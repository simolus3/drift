import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:test/test.dart';

import '../parser/utils.dart';

void main() {
  test('scanns comments', () {
    const sql = r'''
--line
-- line
/*c*/
/*multi
  line */
/* not terminated''';

    // using whereType instead of cast because of the invisible eof token
    final tokens = Scanner(sql).scanTokens().whereType<CommentToken>();

    expect(tokens.map((t) => t.mode), [
      CommentMode.line,
      CommentMode.line,
      CommentMode.cStyle,
      CommentMode.cStyle,
      CommentMode.cStyle,
    ]);

    expect(tokens.map((t) => t.content), [
      'line',
      ' line',
      'c',
      'multi\n  line ',
      ' not terminated',
    ]);
  });
}
