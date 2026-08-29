import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/cloud_config.dart';
import '../models/note.dart';
import '../storage/local_database.dart';

class SyncResult {
  const SyncResult({required this.pushed, required this.pulled});

  final int pushed;
  final int pulled;
}

class SyncService {
  SyncService(this._database);

  final LocalDatabase _database;

  Future<SyncResult> sync() async {
    if (!CloudConfig.enabled) return const SyncResult(pushed: 0, pulled: 0);

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return const SyncResult(pushed: 0, pulled: 0);

    var pushed = 0;
    final dirty = await _database.dirtyNotes();
    for (final note in dirty) {
      await client.from('notes').upsert(
            note.toRemoteMap(user.id),
            onConflict: 'id',
          );
      await _database.markClean(note.id, note.updatedAt.millisecondsSinceEpoch);
      pushed++;
    }

    final previousSync = await _database.lastSyncMillis();
    final lowerBound = previousSync > 2000 ? previousSync - 2000 : 0;
    final rows = await client
        .from('notes')
        .select()
        .gt('updated_at', lowerBound)
        .order('updated_at');

    var newest = previousSync;
    for (final row in rows) {
      final note = Note.fromRemoteMap(row);
      await _database.mergeRemote(note);
      if (note.updatedAt.millisecondsSinceEpoch > newest) {
        newest = note.updatedAt.millisecondsSinceEpoch;
      }
    }
    if (newest > previousSync) await _database.setLastSyncMillis(newest);
    return SyncResult(pushed: pushed, pulled: rows.length);
  }
}
