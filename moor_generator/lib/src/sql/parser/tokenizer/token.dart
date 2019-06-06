import 'package:source_span/source_span.dart';

enum TokenType {
  leftParen,
  rightParen,
  comma,
  dot,
  plus,
  minus,
  star,
  slash,
  less,
  lessEqual,
  more,
  moreEqual,
  equal,

  stringLiteral,
  numberLiteral,
  identifier,

  eof,
}

class Token {
  final TokenType type;

  final SourceSpan span;

  const Token(this.type, this.span);
}

class StringLiteral extends Token {
  final String value;

  /// sqlite allows binary strings (x'literal') which are interpreted as blobs.
  final bool binary;

  const StringLiteral(this.value, SourceSpan span, {this.binary = false})
      : super(TokenType.stringLiteral, span);
}

class IdentifierToken extends Token {
  /// In sql, identifiers can be put in "double quotes", in which case they are
  /// always interpreted as an column name.
  final bool escapedColumnName;

  const IdentifierToken(this.escapedColumnName, SourceSpan span)
      : super(TokenType.identifier, span);
}

class TokenizerError {
  final String message;
  final SourceLocation location;

  TokenizerError(this.message, this.location);
}
