import 'package:flutter_test/flutter_test.dart';
import 'package:tagmemo/src/models/note.dart';

void main() {
  test('database round-trip preserves note fields', () {
    final note = Note(
      id: 'e9e2db04-e895-4a73-87a4-66c7c4983f51',
      title: '買い物',
      body: '牛乳を買う',
      labels: const ['生活', '買い物'],
      colorValue: 0xFFFFF8B8,
      isPinned: true,
      isArchived: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
    );

    final restored = Note.fromDatabaseMap(note.toDatabaseMap());

    expect(restored.id, note.id);
    expect(restored.title, note.title);
    expect(restored.body, note.body);
    expect(restored.labels, note.labels);
    expect(restored.colorValue, note.colorValue);
    expect(restored.isPinned, isTrue);
    expect(restored.isArchived, isFalse);
    expect(restored.updatedAt, note.updatedAt);
  });

  test('remote map uses the authenticated owner', () {
    final note = Note(
      id: 'e9e2db04-e895-4a73-87a4-66c7c4983f51',
      title: '',
      body: '本文',
      labels: const [],
      colorValue: 0xFFFFF8B8,
      isPinned: false,
      isArchived: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
    );

    expect(note.toRemoteMap('owner-id')['user_id'], 'owner-id');
  });
}
