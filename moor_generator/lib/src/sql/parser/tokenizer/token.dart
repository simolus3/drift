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

class TokenizerError {
  final String message;
  final SourceLocation location;

  TokenizerError(this.message, this.location);
}
