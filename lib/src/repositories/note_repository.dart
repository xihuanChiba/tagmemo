import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/note.dart';
import '../platform/widget_bridge.dart';
import '../storage/local_database.dart';
import '../sync/sync_service.dart';

enum NoteSection { notes, archive, trash }

class NoteRepository extends ChangeNotifier {
  NoteRepository(this._database)
      : _syncService = SyncService(_database),
        _widgetBridge = WidgetBridge();

  final LocalDatabase _database;
  final SyncService _syncService;
  final WidgetBridge _widgetBridge;
  final _uuid = const Uuid();

  List<Note> _notes = const [];
  String _query = '';
  String? _selectedLabel;
  NoteSection _section = NoteSection.notes;
  bool _isSyncing = false;
  String? _syncMessage;

  List<Note> get allNotes => List.unmodifiable(_notes);
  String get query => _query;
  String? get selectedLabel => _selectedLabel;
  NoteSection get section => _section;
  bool get isSyncing => _isSyncing;
  String? get syncMessage => _syncMessage;

  List<String> get labels {
    final values = _notes
        .where((note) => !note.isDeleted)
        .expand((note) => note.labels)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<Note> get visibleNotes {
    final normalizedQuery = _query.trim().toLowerCase();
    final result = _notes.where((note) {
      final inSection = switch (_section) {
        NoteSection.notes => !note.isDeleted && !note.isArchived,
        NoteSection.archive => !note.isDeleted && note.isArchived,
        NoteSection.trash => note.isDeleted,
      };
      if (!inSection) return false;
      if (_selectedLabel != null && !note.labels.contains(_selectedLabel)) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;
      return note.title.toLowerCase().contains(normalizedQuery) ||
          note.body.toLowerCase().contains(normalizedQuery) ||
          note.labels.any(
            (label) => label.toLowerCase().contains(normalizedQuery),
          );
    }).toList();
    result.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return result;
  }

  Future<void> initialize() async {
    await _reload();
    unawaited(sync(silent: true));
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void showSection(NoteSection value) {
    _section = value;
    _selectedLabel = null;
    notifyListeners();
  }

  void selectLabel(String? value) {
    _section = NoteSection.notes;
    _selectedLabel = value;
    notifyListeners();
  }

  Future<Note?> save({
    Note? original,
    required String title,
    required String body,
    required List<String> labels,
    required int colorValue,
    required bool isPinned,
    required bool isArchived,
  }) async {
    if (original == null && title.trim().isEmpty && body.trim().isEmpty) {
      return null;
    }
    final now = DateTime.now();
    final normalizedLabels = labels
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final note = original == null
        ? Note(
            id: _uuid.v4(),
            title: title.trim(),
            body: body.trim(),
            labels: normalizedLabels,
            colorValue: colorValue,
            isPinned: isPinned,
            isArchived: isArchived,
            createdAt: now,
            updatedAt: now,
          )
        : original.copyWith(
            title: title.trim(),
            body: body.trim(),
            labels: normalizedLabels,
            colorValue: colorValue,
            isPinned: isPinned,
            isArchived: isArchived,
            updatedAt: now,
            isDirty: true,
          );
    await _database.saveNote(note);
    await _reload();
    unawaited(sync(silent: true));
    return note;
  }

  Future<void> moveToTrash(Note note) async {
    final now = DateTime.now();
    await _database.saveNote(
      note.copyWith(deletedAt: now, updatedAt: now, isDirty: true),
    );
    await _reload();
    unawaited(sync(silent: true));
  }

  Future<void> restore(Note note) async {
    final now = DateTime.now();
    await _database.saveNote(
      note.copyWith(
        clearDeletedAt: true,
        updatedAt: now,
        isDirty: true,
      ),
    );
    await _reload();
    unawaited(sync(silent: true));
  }

  Future<void> togglePinned(Note note) async {
    await save(
      original: note,
      title: note.title,
      body: note.body,
      labels: note.labels,
      colorValue: note.colorValue,
      isPinned: !note.isPinned,
      isArchived: note.isArchived,
    );
  }

  Future<void> sync({bool silent = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    if (!silent) _syncMessage = null;
    notifyListeners();
    try {
      final result = await _syncService.sync();
      await _reload();
      if (!silent) {
        _syncMessage = '送信 ${result.pushed}件・受信 ${result.pulled}件';
      }
    } catch (_) {
      if (!silent) _syncMessage = '同期できませんでした。メモは端末内に保存済みです。';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _reload() async {
    _notes = await _database.listAllNotes();
    await _widgetBridge.update(_notes);
    notifyListeners();
  }
}
