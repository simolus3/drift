import 'package:sqlparser/src/reader/tokenizer/scanner.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';
import 'package:test/test.dart';

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
        'Expected exactly one token when parsing $token, got ${tokens.length - 1}');
  }

  expect(tokens.first.type, type, reason: '$token is a $type');
  expect(tokens.first.span.text, token);
}

Map<String, TokenType> testCases = {
  '(': TokenType.leftParen,
  ')': TokenType.rightParen,
  ',': TokenType.comma,
  '.': TokenType.dot,
  '+': TokenType.plus,
  '-': TokenType.minus,
  '*': TokenType.star,
  '/': TokenType.slash,
  '<=': TokenType.lessEqual,
  '<': TokenType.less,
  '>=': TokenType.moreEqual,
  '>': TokenType.more,
  '!=': TokenType.exclamationEqual,
  "'hello there'": TokenType.stringLiteral,
  '1.123': TokenType.numberLiteral,
  '1.32e5': TokenType.numberLiteral,
  '.123e-3': TokenType.numberLiteral,
  '0xFF13': TokenType.numberLiteral,
  '0Xf13A': TokenType.numberLiteral,
  'SELECT': TokenType.select,
  '"UPDATE"': TokenType.identifier,
};

void main() {
  test('parses single tokens', () {
    testCases.forEach(expectFullToken);
  });
}
