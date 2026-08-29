import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/note.dart';

class WidgetBridge {
  static const _channel = MethodChannel('tagmemo/widget');

  Future<void> update(List<Note> notes) async {
    if (!Platform.isAndroid) return;

    final visible = notes
        .where((note) => !note.isDeleted && !note.isArchived)
        .map(
          (note) => {
            'id': note.id,
            'title': note.title,
            'body': note.body,
            'labels': note.labels,
            'color': note.colorValue,
            'pinned': note.isPinned,
            'updatedAt': note.updatedAt.millisecondsSinceEpoch,
          },
        )
        .toList();
    final labels = visible
        .expand((note) => (note['labels']! as List<String>))
        .toSet()
        .toList()
      ..sort();

    try {
      await _channel.invokeMethod<void>('updateWidget', {
        'notes': jsonEncode(visible),
        'labels': jsonEncode(labels),
      });
    } catch (_) {
      // The memo itself is already saved. A widget refresh can safely retry later.
    }
  }
}
