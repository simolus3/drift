import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

void main() {
  test('parses drift specific tokens', () {
    const part = 'c INTEGER MAPPED BY `const Mapper()` NOT NULL **';
    final tokens = SqlEngine(
      EngineOptions(driftOptions: DriftSqlOptions()),
    ).tokenizeString(part);

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
      tokens.whereType<InlineDartToken>().single.dartCode,
      'const Mapper()',
    );
  });

  test('unterminated dart', () {
    expect(
      () => SqlEngine(
        EngineOptions(driftOptions: DriftSqlOptions()),
      ).tokenizeString('`unterminated dart'),
      throwsA(isA<CumulatedTokenizerException>()),
    );
  });
}
