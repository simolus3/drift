import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:test/test.dart';

void main() {
  test('parses ** as two tokens when not using moor mode', () {
    final tokens = Scanner('**').scanTokens();
    expect(tokens.map((e) => e.type),
        containsAllInOrder([TokenType.star, TokenType.star]));
  });

  test('throws when seeing an invalid token', () {
    expect(
      Scanner('!').scanTokens,
      throwsA(isA<CumulatedTokenizerException>()),
    );
  });

  test('scans identifiers with backticks', () {
    expect(
      Scanner('`SELECT`').scanTokens(),
      contains(isA<IdentifierToken>()
          .having((e) => e.identifier, 'identifier', 'SELECT')),
    );
  });

  test('scans identifiers with double quotes', () {
    expect(
      Scanner('"SELECT"').scanTokens(),
      contains(isA<IdentifierToken>()
          .having((e) => e.identifier, 'identifier', 'SELECT')),
    );
  });
}
