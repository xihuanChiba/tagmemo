import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../models/note.dart';

class LocalDatabase {
  mobile.Database? _database;

  Future<mobile.Database> get database async {
    if (_database != null) return _database!;

    final mobile.DatabaseFactory factory;
    if (Platform.isWindows || Platform.isLinux) {
      ffi.sqfliteFfiInit();
      factory = ffi.databaseFactoryFfi;
    } else {
      // Android/iOS must use the native sqflite plugin. The FFI factory is
      // desktop-only and is not initialized on Android.
      factory = mobile.databaseFactory;
    }

    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final path = p.join(directory.path, 'tagmemo.db');
    _database = await factory.openDatabase(
      path,
      options: mobile.OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA journal_mode=WAL'),
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            labels_json TEXT NOT NULL DEFAULT '[]',
            color_value INTEGER NOT NULL,
            is_pinned INTEGER NOT NULL DEFAULT 0,
            is_archived INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            deleted_at INTEGER,
            is_dirty INTEGER NOT NULL DEFAULT 1
          )
        ''');
          await db.execute(
            'CREATE INDEX notes_updated_at_idx ON notes(updated_at)',
          );
          await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        },
      ),
    );
    return _database!;
  }

  Future<List<Note>> listAllNotes() async {
    final db = await database;
    final rows = await db.query(
      'notes',
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return rows.map(Note.fromDatabaseMap).toList();
  }

  Future<Note?> findNote(String id) async {
    final db = await database;
    final rows = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Note.fromDatabaseMap(rows.single);
  }

  Future<void> saveNote(Note note) async {
    final db = await database;
    await db.insert(
      'notes',
      note.toDatabaseMap(),
      conflictAlgorithm: mobile.ConflictAlgorithm.replace,
    );
  }

  Future<List<Note>> dirtyNotes() async {
    final db = await database;
    final rows = await db.query(
      'notes',
      where: 'is_dirty = 1',
      orderBy: 'updated_at ASC',
    );
    return rows.map(Note.fromDatabaseMap).toList();
  }

  Future<void> markClean(String id, int expectedUpdatedAt) async {
    final db = await database;
    await db.update(
      'notes',
      {'is_dirty': 0},
      where: 'id = ? AND updated_at = ?',
      whereArgs: [id, expectedUpdatedAt],
    );
  }

  Future<void> mergeRemote(Note remote) async {
    final local = await findNote(remote.id);
    if (local != null &&
        local.updatedAt.millisecondsSinceEpoch >=
            remote.updatedAt.millisecondsSinceEpoch) {
      return;
    }
    await saveNote(remote.copyWith(isDirty: false));
  }

  Future<int> lastSyncMillis() async {
    final db = await database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['last_sync_millis'],
    );
    if (rows.isEmpty) return 0;
    return int.tryParse(rows.single['value']! as String) ?? 0;
  }

  Future<void> setLastSyncMillis(int value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'last_sync_millis', 'value': value.toString()},
      conflictAlgorithm: mobile.ConflictAlgorithm.replace,
    );
  }
}
