import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart';

enum TokenType {
  $case,
  $default,
  $do,
  $else,
  $false,
  $for,
  $if,
  $in,
  $index,
  $is,
  $null,
  $true,
  $values,
  $with,
  abort,
  action,
  after,
  all,
  ampersand,
  and,
  as,
  asc,
  atSignVariable,
  autoincrement,
  before,
  begin,
  between,
  by,
  cascade,
  check,
  collate,
  colon,
  colonVariable,
  comma,
  comment,
  conflict,
  constraint,
  create,
  cross,
  current,
  currentDate,
  currentTime,
  currentTimestamp,
  delete,
  desc,
  distinct,
  dollarSignVariable,
  dot,
  doubleEqual,
  doublePipe,
  each,
  end,
  eof,
  equal,
  escape,
  except,
  exclamationEqual,
  exclude,
  exists,
  fail,
  filter,
  following,
  foreign,
  from,
  glob,
  group,
  groups,
  having,
  identifier,
  ignore,
  inner,
  insert,
  instead,
  intersect,
  into,
  isNull,
  join,
  key,
  left,
  leftParen,
  less,
  lessEqual,
  lessMore,
  like,
  limit,
  match,
  minus,
  more,
  moreEqual,
  natural,
  no,
  not,
  notNull,
  nothing,
  numberLiteral,
  of,
  offset,
  on,
  or,
  order,
  others,
  outer,
  over,
  partition,
  percent,
  pipe,
  plus,
  preceding,
  primary,
  questionMarkVariable,
  range,
  recursive,
  references,
  regexp,
  replace,
  restrict,
  rightParen,
  rollback,
  row,
  rowid,
  rows,
  select,
  semicolon,
  set,
  shiftLeft,
  shiftRight,
  slash,
  star,
  stringLiteral,
  table,
  then,
  ties,
  tilde,
  trigger,
  unbounded,
  union,
  unique,
  update,
  using,
  view,
  virtual,
  when,
  where,
  window,
  without,

  /// Moor specific token, used to declare type converter
  mapped,
  inlineDart,
  import,
  json,

  /// A `**` token. This is only scanned when scanning for moor tokens.
  doubleStar,
}

const Map<String, TokenType> keywords = {
  'ABORT': TokenType.abort,
  'ACTION': TokenType.action,
  'AFTER': TokenType.after,
  'ALL': TokenType.all,
  'AND': TokenType.and,
  'AS': TokenType.as,
  'ASC': TokenType.asc,
  'AUTOINCREMENT': TokenType.autoincrement,
  'BEFORE': TokenType.before,
  'BEGIN': TokenType.begin,
  'BETWEEN': TokenType.between,
  'BY': TokenType.by,
  'CASCADE': TokenType.cascade,
  'CASE': TokenType.$case,
  'CHECK': TokenType.check,
  'COLLATE': TokenType.collate,
  'CONFLICT': TokenType.conflict,
  'CONSTRAINT': TokenType.constraint,
  'CREATE': TokenType.create,
  'CROSS': TokenType.cross,
  'CURRENT': TokenType.current,
  'CURRENT_DATE': TokenType.currentDate,
  'CURRENT_TIME': TokenType.currentTime,
  'CURRENT_TIMESTAMP': TokenType.currentTimestamp,
  'DEFAULT': TokenType.$default,
  'DELETE': TokenType.delete,
  'DESC': TokenType.desc,
  'DISTINCT': TokenType.distinct,
  'DO': TokenType.$do,
  'EACH': TokenType.each,
  'ELSE': TokenType.$else,
  'END': TokenType.end,
  'ESCAPE': TokenType.escape,
  'EXCEPT': TokenType.except,
  'EXCLUDE': TokenType.exclude,
  'EXISTS': TokenType.exists,
  'FAIL': TokenType.fail,
  'FALSE': TokenType.$false,
  'FILTER': TokenType.filter,
  'FOLLOWING': TokenType.following,
  'FOR': TokenType.$for,
  'FOREIGN': TokenType.foreign,
  'FROM': TokenType.from,
  'GLOB': TokenType.glob,
  'GROUP': TokenType.group,
  'GROUPS': TokenType.groups,
  'HAVING': TokenType.having,
  'IF': TokenType.$if,
  'IGNORE': TokenType.ignore,
  'IN': TokenType.$in,
  'INDEX': TokenType.$index,
  'INNER': TokenType.inner,
  'INSERT': TokenType.insert,
  'INSTEAD': TokenType.instead,
  'INTERSECT': TokenType.intersect,
  'INTO': TokenType.into,
  'IS': TokenType.$is,
  'ISNULL': TokenType.isNull,
  'JOIN': TokenType.join,
  'KEY': TokenType.key,
  'LEFT': TokenType.left,
  'LIKE': TokenType.like,
  'LIMIT': TokenType.limit,
  'MATCH': TokenType.match,
  'NATURAL': TokenType.natural,
  'NO': TokenType.no,
  'NOT': TokenType.not,
  'NOTHING': TokenType.nothing,
  'NOTNULL': TokenType.notNull,
  'NULL': TokenType.$null,
  'OF': TokenType.of,
  'OFFSET': TokenType.offset,
  'ON': TokenType.on,
  'OR': TokenType.or,
  'ORDER': TokenType.order,
  'OTHERS': TokenType.others,
  'OUTER': TokenType.outer,
  'OVER': TokenType.over,
  'PARTITION': TokenType.partition,
  'PRECEDING': TokenType.preceding,
  'PRIMARY': TokenType.primary,
  'RANGE': TokenType.range,
  'RECURSIVE': TokenType.recursive,
  'REFERENCES': TokenType.references,
  'REGEXP': TokenType.regexp,
  'REPLACE': TokenType.replace,
  'RESTRICT': TokenType.restrict,
  'ROLLBACK': TokenType.rollback,
  'ROW': TokenType.row,
  'ROWID': TokenType.rowid,
  'ROWS': TokenType.rows,
  'SELECT': TokenType.select,
  'SET': TokenType.set,
  'TABLE': TokenType.table,
  'THEN': TokenType.then,
  'TIES': TokenType.ties,
  'TRIGGER': TokenType.trigger,
  'TRUE': TokenType.$true,
  'UNBOUNDED': TokenType.unbounded,
  'UNION': TokenType.union,
  'UNIQUE': TokenType.unique,
  'UPDATE': TokenType.update,
  'USING': TokenType.using,
  'VALUES': TokenType.$values,
  'VIEW': TokenType.view,
  'VIRTUAL': TokenType.virtual,
  'WHEN': TokenType.when,
  'WHERE': TokenType.where,
  'WINDOW': TokenType.window,
  'WITH': TokenType.$with,
  'WITHOUT': TokenType.without,
};

/// Maps [TokenType]s which are keywords to their lexeme.
final Map<TokenType, String> reverseKeywords = {
  for (var entry in keywords.entries) entry.value: entry.key,
  for (var entry in moorKeywords.entries) entry.value: entry.key,
};

const Map<String, TokenType> moorKeywords = {
  'IMPORT': TokenType.import,
  'JSON': TokenType.json,
  'MAPPED': TokenType.mapped,
};

/// A set of [TokenType]s that can be parsed as an identifier.
const Set<TokenType> _identifierKeywords = {
  TokenType.join,
  TokenType.rowid,
};

/// Returns true if the [type] belongs to a keyword
bool isKeyword(TokenType type) => reverseKeywords.containsKey(type);

/// Returns true if [name] is a reserved keyword in sqlite.
bool isKeywordLexeme(String name) => keywords.containsKey(name.toUpperCase());

class Token implements SyntacticEntity {
  final TokenType type;

  /// Whether this token should be invisible to the parser. We use this for
  /// comment tokens.
  bool get invisibleToParser => false;

  @override
  final FileSpan span;
  String get lexeme => span.text;

  /// The index of this [Token] in the list of tokens scanned.
  int index;

  Token(this.type, this.span);

  @override
  bool get hasSpan => true;

  @override
  String toString() {
    return '$type: $lexeme';
  }

  @override
  int get firstPosition => span.start.offset;

  @override
  int get lastPosition => span.end.offset;

  @override
  bool get synthetic => false;
}

class StringLiteralToken extends Token {
  final String value;

  /// sqlite allows binary strings (x'literal') which are interpreted as blobs.
  final bool binary;

  StringLiteralToken(this.value, FileSpan span, {this.binary = false})
      : super(TokenType.stringLiteral, span);
}

class IdentifierToken extends Token {
  /// Whether this identifier was escaped by putting it in "double ticks".
  final bool escaped;

  /// Whether this identifier token is synthetic. We sometimes convert
  /// [KeywordToken]s to identifiers if they're unambiguous, in which case
  /// [synthetic] will be true on this token because it was not scanned as such.
  @override
  final bool synthetic;

  String get identifier {
    if (escaped) {
      return lexeme.substring(1, lexeme.length - 1);
    } else {
      return lexeme;
    }
  }

  IdentifierToken(this.escaped, FileSpan span, {this.synthetic = false})
      : super(TokenType.identifier, span);
}

abstract class VariableToken extends Token {
  VariableToken(TokenType type, FileSpan span) : super(type, span);
}

class QuestionMarkVariableToken extends Token {
  /// The explicit index, if this variable was of the form `?123`. Otherwise
  /// null.
  final int explicitIndex;

  QuestionMarkVariableToken(FileSpan span, this.explicitIndex)
      : super(TokenType.questionMarkVariable, span);
}

class ColonVariableToken extends Token {
  final String name;

  ColonVariableToken(FileSpan span, this.name)
      : super(TokenType.colonVariable, span);
}

class DollarSignVariableToken extends Token {
  final String name;

  DollarSignVariableToken(FileSpan span, this.name)
      : super(TokenType.dollarSignVariable, span);
}

class AtSignVariableToken extends Token {
  final String name;

  AtSignVariableToken(FileSpan span, this.name)
      : super(TokenType.atSignVariable, span);
}

/// Inline Dart appearing in a create table statement. Only parsed when the moor
/// extensions are enabled. Dart code is wrapped in backticks.
class InlineDartToken extends Token {
  InlineDartToken(FileSpan span) : super(TokenType.inlineDart, span);

  String get dartCode {
    // strip the backticks
    return lexeme.substring(1, lexeme.length - 1);
  }
}

/// Used for tokens that are keywords. We use this special class without any
/// additional properties to ease syntax highlighting, as it allows us to find
/// the keywords easily.
class KeywordToken extends Token {
  /// Whether this token has been used as an identifier while parsing.
  bool isIdentifier = false;

  KeywordToken(TokenType type, FileSpan span) : super(type, span);

  bool canConvertToIdentifier() {
    // https://stackoverflow.com/a/45775719, but we don't parse indexed yet.
    return _identifierKeywords.contains(type) ||
        moorKeywords.values.contains(type);
  }

  IdentifierToken convertToIdentifier() {
    isIdentifier = true;

    return IdentifierToken(false, span, synthetic: false);
  }
}

enum CommentMode { line, cStyle }

/// A comment, either started with -- or with /*.
class CommentToken extends Token {
  final CommentMode mode;

  /// The content of this comment, excluding the "--", "/*", "*/".
  final String content;

  @override
  final bool invisibleToParser = true;

  CommentToken(this.mode, this.content, FileSpan span)
      : super(TokenType.comment, span);
}

class TokenizerError {
  final String message;
  final SourceLocation location;

  TokenizerError(this.message, this.location);

  @override
  String toString() {
    return '$message at $location';
  }
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
