import 'package:test/test.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';

void main() {
  test('parses moor specific tokens', () {
    const part = 'c INTEGER MAPPED BY `const Mapper()` NOT NULL **';
    final scanner = Scanner(part, scanMoorTokens: true);
    final tokens = scanner.scanTokens();

    expect(scanner.errors, isEmpty);
    expect(tokens.map((t) => t.type), [
      TokenType.identifier, // c
      TokenType.identifier, // INTEGER
      TokenType.mapped,
      TokenType.by,
      TokenType.inlineDart, // `const Mapper()`
      TokenType.not,
      TokenType.$null,
      TokenType.doubleStar,
      TokenType.eof,
    ]);

    expect(
        tokens.whereType<InlineDartToken>().single.dartCode, 'const Mapper()');
  });
}
