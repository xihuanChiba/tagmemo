import 'package:flutter_test/flutter_test.dart';
import 'package:tagmemo/src/markdown/markdown_tools.dart';

void main() {
  test('parses and toggles markdown checklist items', () {
    const source = '## 買い物\n- [ ] 牛乳\n- [x] パン';

    final open = parseMarkdownTaskLine('- [ ] 牛乳');
    final done = parseMarkdownTaskLine('- [x] パン');

    expect(open?.checked, isFalse);
    expect(open?.text, '牛乳');
    expect(done?.checked, isTrue);
    expect(setMarkdownTaskChecked(source, 1, true), contains('- [x] 牛乳'));
  });

  test('creates a readable summary from markdown', () {
    const source = '## 今日の予定\n- [ ] **買い物**\n[資料](https://example.com)';

    expect(markdownSummary(source), '今日の予定\n☐ 買い物\n資料');
  });
}
