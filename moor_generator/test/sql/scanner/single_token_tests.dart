import 'package:moor_generator/src/sql/parser/tokenizer/scanner.dart';
import 'package:moor_generator/src/sql/parser/tokenizer/token.dart';
import 'package:test_api/test_api.dart';

void expectFullToken(String token, TokenType type) {
  final scanner = Scanner(token);
  List<Token> tokens;
  try {
    tokens = scanner.scanTokens();
  } catch (e, s) {
    print(e);
    print(s);
    fail('Parsing error while parsing $token');
  }

  if (tokens.length != 2 || tokens.last.type != TokenType.eof) {
    fail(
        'Expected exactly one token when parsing $token, got ${tokens.length}');
  }

  expect(tokens.first.type, type, reason: '$token is a $type');
}

Map<String, TokenType> testCases = {
  '.': TokenType.dot,
  "'hello there'": TokenType.stringLiteral,
};

void main() {
  test('parses single tokens', () {
    testCases.forEach(expectFullToken);
  });
}
