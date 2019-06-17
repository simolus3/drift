part of 'parser.dart';

/// Parses a number from the [lexeme] assuming it has a form conforming to
/// https://www.sqlite.org/syntax/numeric-literal.html
num _parseNumber(String lexeme) {
  if (lexeme.startsWith('0x')) {
    return int.parse(lexeme.substring(2), radix: 16);
  }

  return double.parse(lexeme);
}
