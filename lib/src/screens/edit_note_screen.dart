import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';

import '../markdown/markdown_tools.dart';
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
    0xFFC8E6C9,
    0xFFB3E5FC,
  ];

  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _labels;
  late int _color;
  late bool _pinned;
  late bool _archived;
  bool _saving = false;
  bool _preview = false;

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

  void _insertWrapped(String prefix, String suffix, String placeholder) {
    final text = _body.text;
    final selection = _body.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final selected = text.substring(start, end);
    final content = selected.isEmpty ? placeholder : selected;
    final replacement = '$prefix$content$suffix';
    final nextText = text.replaceRange(start, end, replacement);
    final contentStart = start + prefix.length;
    _body.value = TextEditingValue(
      text: nextText,
      selection: selected.isEmpty
          ? TextSelection(
              baseOffset: contentStart,
              extentOffset: contentStart + placeholder.length,
            )
          : TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  void _insertLinePrefix(String prefix) {
    final text = _body.text;
    final selection = _body.selection;
    final cursor = selection.isValid ? selection.start : text.length;
    final lineStart = cursor == 0 ? 0 : text.lastIndexOf('\n', cursor - 1) + 1;
    _body.value = TextEditingValue(
      text: text.replaceRange(lineStart, lineStart, prefix),
      selection: TextSelection.collapsed(offset: cursor + prefix.length),
    );
  }

  void _toggleTask(int lineIndex, bool checked) {
    final nextText = setMarkdownTaskChecked(_body.text, lineIndex, checked);
    setState(() {
      _body.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
    });
  }

  String _formatDate(DateTime value) =>
      DateFormat('yyyy/MM/dd HH:mm').format(value);

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
              tooltip: _preview ? '編集に戻る' : 'Markdownをプレビュー',
              onPressed: () => setState(() => _preview = !_preview),
              icon: Icon(_preview ? Icons.edit_outlined : Icons.visibility),
            ),
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
              if (_preview)
                _MarkdownPreview(
                  data: _body.text,
                  onTaskChanged: _toggleTask,
                )
              else ...[
                _MarkdownToolbar(
                  onChecklist: () => _insertLinePrefix('- [ ] '),
                  onHeading: () => _insertLinePrefix('## '),
                  onBold: () => _insertWrapped('**', '**', '太字'),
                  onBullet: () => _insertLinePrefix('- '),
                  onCode: () => _insertWrapped('`', '`', 'コード'),
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
              ],
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
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.schedule_outlined, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: widget.note == null
                        ? const Text(
                            '作成日時・更新日時は初回保存時に記録されます',
                          )
                        : Text(
                            '作成 ${_formatDate(widget.note!.createdAt)}\n'
                            '更新 ${_formatDate(widget.note!.updatedAt)}',
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkdownToolbar extends StatelessWidget {
  const _MarkdownToolbar({
    required this.onChecklist,
    required this.onHeading,
    required this.onBold,
    required this.onBullet,
    required this.onCode,
  });

  final VoidCallback onChecklist;
  final VoidCallback onHeading;
  final VoidCallback onBold;
  final VoidCallback onBullet;
  final VoidCallback onCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              IconButton(
                tooltip: 'チェック項目',
                onPressed: onChecklist,
                icon: const Icon(Icons.check_box_outlined),
              ),
              IconButton(
                tooltip: '見出し',
                onPressed: onHeading,
                icon: const Icon(Icons.title),
              ),
              IconButton(
                tooltip: '太字',
                onPressed: onBold,
                icon: const Icon(Icons.format_bold),
              ),
              IconButton(
                tooltip: '箇条書き',
                onPressed: onBullet,
                icon: const Icon(Icons.format_list_bulleted),
              ),
              IconButton(
                tooltip: 'コード',
                onPressed: onCode,
                icon: const Icon(Icons.code),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            'Markdown対応：右上の目のボタンで表示を確認できます',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview({
    required this.data,
    required this.onTaskChanged,
  });

  final String data;
  final void Function(int lineIndex, bool checked) onTaskChanged;

  @override
  Widget build(BuildContext context) {
    if (data.trim().isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: Text('本文はまだありません')),
      );
    }

    final children = <Widget>[];
    final markdownLines = <String>[];

    void flushMarkdown() {
      if (markdownLines.isEmpty) return;
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: MarkdownBody(
            data: markdownLines.join('\n'),
            selectable: true,
          ),
        ),
      );
      markdownLines.clear();
    }

    final lines = data.split('\n');
    for (var index = 0; index < lines.length; index++) {
      final task = parseMarkdownTaskLine(lines[index]);
      if (task == null) {
        markdownLines.add(lines[index]);
        continue;
      }

      flushMarkdown();
      children.add(
        CheckboxListTile(
          value: task.checked,
          onChanged: (value) => onTaskChanged(index, value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: MarkdownBody(data: task.text, selectable: true),
        ),
      );
    }
    flushMarkdown();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
