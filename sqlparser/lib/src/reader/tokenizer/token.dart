import 'package:source_span/source_span.dart';

enum TokenType {
  leftParen,
  rightParen,
  comma,
  dot,
  doublePipe,
  star,
  slash,
  percent,
  plus,
  minus,
  shiftLeft,
  shiftRight,
  ampersand,
  pipe,
  less,
  lessEqual,
  more,
  moreEqual,
  equal,
  doubleEqual,
  exclamationEqual,
  lessMore,
  $is,
  $in,
  not,
  like,
  glob,
  match,
  regexp,
  and,
  or,
  tilde,
  between,

  questionMark,
  colon,
  // todo at and dollarSign are currently not used
  at,
  dollarSign,

  stringLiteral,
  numberLiteral,
  $true,
  $false,
  $null,
  currentTime,
  currentDate,
  currentTimestamp,
  identifier,

  select,
  delete,
  distinct,
  all,
  from,
  as,
  where,

  natural,
  left,
  outer,
  inner,
  cross,
  join,
  on,
  using,

  group,
  order,
  by,
  asc,
  desc,
  having,

  limit,
  offset,

  $case,
  when,
  then,
  $else,
  end,

  semicolon,
  eof,
}

const Map<String, TokenType> keywords = {
  'SELECT': TokenType.select,
  'DISTINCT': TokenType.distinct,
  'ALL': TokenType.all,
  'AND': TokenType.and,
  'OR': TokenType.or,
  'BETWEEN': TokenType.between,
  'DELETE': TokenType.delete,
  'FROM': TokenType.from,
  'NATURAL': TokenType.natural,
  'LEFT': TokenType.leftParen,
  'OUTER': TokenType.outer,
  'INNER': TokenType.inner,
  'CROSS': TokenType.cross,
  'JOIN': TokenType.join,
  'ON': TokenType.on,
  'USING': TokenType.using,
  'AS': TokenType.as,
  'WHERE': TokenType.where,
  'ORDER': TokenType.order,
  'GROUP': TokenType.group,
  'HAVING': TokenType.having,
  'BY': TokenType.by,
  'ASC': TokenType.asc,
  'DESC': TokenType.desc,
  'LIMIT': TokenType.limit,
  'OFFSET': TokenType.offset,
  'IS': TokenType.$is,
  'IN': TokenType.$in,
  'LIKE': TokenType.like,
  'GLOB': TokenType.glob,
  'MATCH': TokenType.match,
  'REGEXP': TokenType.regexp,
  'NOT': TokenType.not,
  'TRUE': TokenType.$true,
  'FALSE': TokenType.$false,
  'NULL': TokenType.$null,
  'CURRENT_TIME': TokenType.currentTime,
  'CURRENT_DATE': TokenType.currentDate,
  'CURRENT_TIMESTAMP': TokenType.currentTimestamp,
  'CASE': TokenType.$case,
  'WHEN': TokenType.when,
  'THEN': TokenType.then,
  'ELSE': TokenType.$else,
  'END': TokenType.end,
};

class Token {
  final TokenType type;

  final SourceSpan span;
  String get lexeme => span.text;

  const Token(this.type, this.span);
}

class StringLiteralToken extends Token {
  final String value;

  /// sqlite allows binary strings (x'literal') which are interpreted as blobs.
  final bool binary;

  const StringLiteralToken(this.value, SourceSpan span, {this.binary = false})
      : super(TokenType.stringLiteral, span);
}

class IdentifierToken extends Token {
  /// Whether this identifier was escaped by putting it in "double ticks".
  final bool escaped;

  String get identifier {
    if (escaped) {
      return lexeme.substring(1, lexeme.length - 1);
    } else {
      return lexeme;
    }
  }

  const IdentifierToken(this.escaped, SourceSpan span)
      : super(TokenType.identifier, span);
}

class TokenizerError {
  final String message;
  final SourceLocation location;

  TokenizerError(this.message, this.location);
}

/// Thrown by the sql engine when a sql statement can't be tokenized.
class CumulatedTokenizerException implements Exception {
  final List<TokenizerError> errors;
  CumulatedTokenizerException(this.errors);

  @override
  String toString() {
    final explanation =
        errors.map((e) => '${e.message} at ${e.location}').join(', ');
    return 'Malformed sql: $explanation';
  }
}
