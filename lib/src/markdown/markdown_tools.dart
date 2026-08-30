final _taskPattern = RegExp(r'^(\s*)[-*]\s+\[([ xX])\]\s+(.*)$');

class MarkdownTaskLine {
  const MarkdownTaskLine({
    required this.indent,
    required this.checked,
    required this.text,
  });

  final String indent;
  final bool checked;
  final String text;

  String withChecked(bool value) =>
      '$indent- [${value ? 'x' : ' '}] $text';
}

MarkdownTaskLine? parseMarkdownTaskLine(String line) {
  final match = _taskPattern.firstMatch(line);
  if (match == null) return null;
  return MarkdownTaskLine(
    indent: match.group(1)!,
    checked: match.group(2)!.toLowerCase() == 'x',
    text: match.group(3)!,
  );
}

String setMarkdownTaskChecked(String source, int lineIndex, bool checked) {
  final lines = source.split('\n');
  if (lineIndex < 0 || lineIndex >= lines.length) return source;
  final task = parseMarkdownTaskLine(lines[lineIndex]);
  if (task == null) return source;
  lines[lineIndex] = task.withChecked(checked);
  return lines.join('\n');
}

String markdownSummary(String source) {
  final lines = source.split('\n').map((line) {
    final task = parseMarkdownTaskLine(line);
    if (task != null) return '${task.checked ? '☑' : '☐'} ${task.text}';

    var result = line
        .replaceFirst(RegExp(r'^\s*#{1,6}\s+'), '')
        .replaceFirst(RegExp(r'^\s*>\s?'), '')
        .replaceFirst(RegExp(r'^\s*[-*+]\s+'), '• ')
        .replaceFirst(RegExp(r'^\s*\d+[.)]\s+'), '');
    result = result.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\]\([^)]+\)'),
      (match) => match.group(1)!,
    );
    result = result.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (match) => match.group(1)!,
    );
    return result.replaceAll(RegExp(r'[*_`~]'), '');
  }).join('\n');

  return lines.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}
