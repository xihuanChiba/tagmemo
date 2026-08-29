import 'package:flutter/material.dart';

import '../models/note.dart';
import '../repositories/note_repository.dart';

class EditNoteScreen extends StatefulWidget {
  const EditNoteScreen({
    super.key,
    required this.repository,
    this.note,
  });

  final NoteRepository repository;
  final Note? note;

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  static const _colors = [
    0xFFFFF8B8,
    0xFFF8BBD0,
    0xFFFFCC80,
    0xFFC8E6C9,
    0xFFB3E5FC,
    0xFFD1C4E9,
    0xFFF5F5F5,
  ];

  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _labels;
  late int _color;
  late bool _pinned;
  late bool _archived;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _title = TextEditingController(text: note?.title ?? '');
    _body = TextEditingController(text: note?.body ?? '');
    _labels = TextEditingController(text: note?.labels.join(', ') ?? '');
    _color = note?.colorValue ?? _colors.first;
    _pinned = note?.isPinned ?? false;
    _archived = note?.isArchived ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _labels.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.repository.save(
      original: widget.note,
      title: _title.text,
      body: _body.text,
      labels: _labels.text.split(RegExp('[,、]')),
      colorValue: _color,
      isPinned: _pinned,
      isArchived: _archived,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _saveAndClose();
      },
      child: Scaffold(
        backgroundColor: Color(_color),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            tooltip: '保存して戻る',
            onPressed: _saveAndClose,
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              tooltip: _pinned ? '固定を解除' : '固定',
              onPressed: () => setState(() => _pinned = !_pinned),
              icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
            ),
            IconButton(
              tooltip: _archived ? 'アーカイブ解除' : 'アーカイブ',
              onPressed: () => setState(() => _archived = !_archived),
              icon: Icon(
                _archived ? Icons.unarchive_outlined : Icons.archive_outlined,
              ),
            ),
            if (widget.note != null)
              IconButton(
                tooltip: 'ゴミ箱へ移動',
                onPressed: () async {
                  await widget.repository.moveToTrash(widget.note!);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              TextField(
                controller: _title,
                maxLines: null,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                decoration: const InputDecoration(
                  hintText: 'タイトル',
                  border: InputBorder.none,
                ),
              ),
              TextField(
                controller: _body,
                minLines: 12,
                maxLines: null,
                autofocus: widget.note == null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'メモを入力…',
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _labels,
                decoration: const InputDecoration(
                  labelText: 'ラベル',
                  hintText: '仕事, 買い物（カンマ区切り）',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 20),
              Text('色', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _colors
                    .map(
                      (color) => InkWell(
                        onTap: () => setState(() => _color = color),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == color
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black26,
                              width: _color == color ? 3 : 1,
                            ),
                          ),
                          child: _color == color
                              ? const Icon(Icons.check, size: 20)
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
