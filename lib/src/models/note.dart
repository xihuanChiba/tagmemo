import 'dart:convert';

class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.labels,
    required this.colorValue,
    required this.isPinned,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isDirty = true,
  });

  final String id;
  final String title;
  final String body;
  final List<String> labels;
  final int colorValue;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDirty;

  bool get isDeleted => deletedAt != null;

  Note copyWith({
    String? title,
    String? body,
    List<String>? labels,
    int? colorValue,
    bool? isPinned,
    bool? isArchived,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool? isDirty,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      labels: labels ?? this.labels,
      colorValue: colorValue ?? this.colorValue,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  Map<String, Object?> toDatabaseMap() => {
        'id': id,
        'title': title,
        'body': body,
        'labels_json': jsonEncode(labels),
        'color_value': colorValue,
        'is_pinned': isPinned ? 1 : 0,
        'is_archived': isArchived ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
        'is_dirty': isDirty ? 1 : 0,
      };

  Map<String, Object?> toRemoteMap(String userId) => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'labels': labels,
        'color_value': colorValue,
        'is_pinned': isPinned,
        'is_archived': isArchived,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory Note.fromDatabaseMap(Map<String, Object?> map) {
    return Note(
      id: map['id']! as String,
      title: map['title']! as String,
      body: map['body']! as String,
      labels: (jsonDecode(map['labels_json']! as String) as List<dynamic>)
          .cast<String>(),
      colorValue: map['color_value']! as int,
      isPinned: map['is_pinned'] == 1,
      isArchived: map['is_archived'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['deleted_at']! as int),
      isDirty: map['is_dirty'] == 1,
    );
  }

  factory Note.fromRemoteMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      labels: ((map['labels'] as List<dynamic>?) ?? const []).cast<String>(),
      colorValue: (map['color_value'] as num?)?.toInt() ?? 0xFFFFF8B8,
      isPinned: (map['is_pinned'] as bool?) ?? false,
      isArchived: (map['is_archived'] as bool?) ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as num).toInt(),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updated_at'] as num).toInt(),
      ),
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (map['deleted_at'] as num).toInt(),
            ),
      isDirty: false,
    );
  }
}
