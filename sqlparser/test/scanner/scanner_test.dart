import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:test/test.dart';

void main() {
  test('parses ** as two tokens when not using drift mode', () {
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

  test('scans new tokens for JSON extraction', () {
    expect(Scanner('- -> ->>').scanTokens(), [
      isA<Token>().having((e) => e.type, 'tokenType', TokenType.minus),
      isA<Token>().having((e) => e.type, 'tokenType', TokenType.dashRangle),
      isA<Token>()
          .having((e) => e.type, 'tokenType', TokenType.dashRangleRangle),
      isA<Token>().having((e) => e.type, 'tokenType', TokenType.eof),
    ]);
  });

  group('reports error message', () {
    test(r'for missing identifier after `$`', () {
      expect(
        Scanner(r'$ order').scanTokens,
        throwsA(
          isA<CumulatedTokenizerException>().having(
            (e) => e.errors,
            'errors',
            contains(
              isA<TokenizerError>()
                  .having((e) => e.message, 'message',
                      r'Expected identifier after `$`')
                  .having((e) => e.location.offset, 'location.offset', 1),
            ),
          ),
        ),
      );
    });

    test('for missing identifier after `@`', () {
      expect(
        Scanner(r'@ order').scanTokens,
        throwsA(
          isA<CumulatedTokenizerException>().having(
            (e) => e.errors,
            'errors',
            contains(
              isA<TokenizerError>()
                  .having((e) => e.message, 'message',
                      r'Expected identifier after `@`')
                  .having((e) => e.location.offset, 'location.offset', 1),
            ),
          ),
        ),
      );
    });
  });
}
