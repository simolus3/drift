import 'dart:math';

import 'package:meta/meta.dart';
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
  add,
  after,
  all,
  alter,
  always,
  ampersand,
  analyze,
  and,
  as,
  asc,
  atSignVariable,
  attach,
  autoincrement,
  before,
  begin,
  between,
  by,
  cascade,
  cast,
  check,
  collate,
  colon,
  column,
  colonVariable,
  comma,
  comment,
  commit,
  conflict,
  constraint,
  create,
  cross,
  current,
  currentDate,
  currentTime,
  currentTimestamp,
  database,
  deferrable,
  deferred,
  delete,
  desc,
  detach,
  distinct,
  dollarSignVariable,
  dot,
  doubleEqual,
  doublePipe,
  drop,
  each,
  end,
  eof,
  equal,
  escape,
  except,
  exclamationEqual,
  exclude,
  exclusive,
  exists,
  explain,
  fail,
  filter,
  first,
  following,
  foreign,
  from,
  full,
  generated,
  glob,
  group,
  groups,
  having,
  identifier,
  ignore,
  immediate,
  indexed,
  initially,
  inner,
  insert,
  instead,
  intersect,
  into,
  isNull,
  join,
  key,
  last,
  left,
  leftParen,
  less,
  lessEqual,
  lessMore,
  like,
  limit,
  match,
  materialized,
  minus,
  more,
  moreEqual,
  natural,
  no,
  not,
  notNull,
  nothing,
  nulls,
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
  plan,
  plus,
  pragma,
  preceding,
  primary,
  query,
  questionMarkVariable,
  range,
  raise,
  recursive,
  references,
  regexp,
  reindex,
  release,
  rename,
  replace,
  returning,
  restrict,
  right,
  rightParen,
  rollback,
  row,
  rowid,
  rows,
  savepoint,
  select,
  semicolon,
  set,
  shiftLeft,
  shiftRight,
  slash,
  star,
  strict,
  stringLiteral,
  table,
  temp,
  temporary,
  then,
  ties,
  tilde,
  to,
  transaction,
  trigger,
  unbounded,
  union,
  unique,
  update,
  using,
  vacuum,
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
  required,

  /// A `**` token. This is only scanned when scanning for moor tokens.
  doubleStar,
}

const Map<String, TokenType> keywords = {
  'ADD': TokenType.add,
  'ABORT': TokenType.abort,
  'ACTION': TokenType.action,
  'AFTER': TokenType.after,
  'ALL': TokenType.all,
  'ALTER': TokenType.alter,
  'ALWAYS': TokenType.always,
  'ANALYZE': TokenType.analyze,
  'AND': TokenType.and,
  'AS': TokenType.as,
  'ASC': TokenType.asc,
  'ATTACH': TokenType.attach,
  'AUTOINCREMENT': TokenType.autoincrement,
  'BEFORE': TokenType.before,
  'BEGIN': TokenType.begin,
  'BETWEEN': TokenType.between,
  'BY': TokenType.by,
  'CASCADE': TokenType.cascade,
  'CASE': TokenType.$case,
  'CAST': TokenType.cast,
  'CHECK': TokenType.check,
  'COLLATE': TokenType.collate,
  'COLUMN': TokenType.column,
  'COMMIT': TokenType.commit,
  'CONFLICT': TokenType.conflict,
  'CONSTRAINT': TokenType.constraint,
  'CREATE': TokenType.create,
  'CROSS': TokenType.cross,
  'CURRENT': TokenType.current,
  'CURRENT_DATE': TokenType.currentDate,
  'CURRENT_TIME': TokenType.currentTime,
  'CURRENT_TIMESTAMP': TokenType.currentTimestamp,
  'DATABASE': TokenType.database,
  'DEFAULT': TokenType.$default,
  'DEFERRABLE': TokenType.deferrable,
  'DEFERRED': TokenType.deferred,
  'DELETE': TokenType.delete,
  'DESC': TokenType.desc,
  'DETACH': TokenType.detach,
  'DISTINCT': TokenType.distinct,
  'DO': TokenType.$do,
  'DROP': TokenType.drop,
  'EACH': TokenType.each,
  'ELSE': TokenType.$else,
  'END': TokenType.end,
  'ESCAPE': TokenType.escape,
  'EXCEPT': TokenType.except,
  'EXCLUDE': TokenType.exclude,
  'EXCLUSIVE': TokenType.exclusive,
  'EXISTS': TokenType.exists,
  'EXPLAIN': TokenType.explain,
  'FAIL': TokenType.fail,
  'FALSE': TokenType.$false,
  'FILTER': TokenType.filter,
  'FIRST': TokenType.first,
  'FOLLOWING': TokenType.following,
  'FOR': TokenType.$for,
  'FOREIGN': TokenType.foreign,
  'FROM': TokenType.from,
  'FULL': TokenType.full,
  'GENERATED': TokenType.generated,
  'GLOB': TokenType.glob,
  'GROUP': TokenType.group,
  'GROUPS': TokenType.groups,
  'HAVING': TokenType.having,
  'IF': TokenType.$if,
  'IGNORE': TokenType.ignore,
  'IMMEDIATE': TokenType.immediate,
  'IN': TokenType.$in,
  'INDEX': TokenType.$index,
  'INDEXED': TokenType.indexed,
  'INITIALLY': TokenType.initially,
  'INNER': TokenType.inner,
  'INSERT': TokenType.insert,
  'INSTEAD': TokenType.instead,
  'INTERSECT': TokenType.intersect,
  'INTO': TokenType.into,
  'IS': TokenType.$is,
  'ISNULL': TokenType.isNull,
  'JOIN': TokenType.join,
  'KEY': TokenType.key,
  'LAST': TokenType.last,
  'LEFT': TokenType.left,
  'LIKE': TokenType.like,
  'LIMIT': TokenType.limit,
  'MATCH': TokenType.match,
  'MATERIALIZED': TokenType.materialized,
  'NATURAL': TokenType.natural,
  'NO': TokenType.no,
  'NOT': TokenType.not,
  'NOTHING': TokenType.nothing,
  'NOTNULL': TokenType.notNull,
  'NULL': TokenType.$null,
  'NULLS': TokenType.nulls,
  'OF': TokenType.of,
  'OFFSET': TokenType.offset,
  'ON': TokenType.on,
  'OR': TokenType.or,
  'ORDER': TokenType.order,
  'OTHERS': TokenType.others,
  'OUTER': TokenType.outer,
  'OVER': TokenType.over,
  'PARTITION': TokenType.partition,
  'PLAN': TokenType.plan,
  'PRAGMA': TokenType.pragma,
  'PRECEDING': TokenType.preceding,
  'PRIMARY': TokenType.primary,
  'QUERY': TokenType.query,
  'RAISE': TokenType.raise,
  'RANGE': TokenType.range,
  'RECURSIVE': TokenType.recursive,
  'REFERENCES': TokenType.references,
  'REGEXP': TokenType.regexp,
  'REINDEX': TokenType.reindex,
  'RELEASE': TokenType.release,
  'RENAME': TokenType.rename,
  'REPLACE': TokenType.replace,
  'RIGHT': TokenType.right,
  'RETURNING': TokenType.returning,
  'RESTRICT': TokenType.restrict,
  'ROLLBACK': TokenType.rollback,
  'ROW': TokenType.row,
  'ROWID': TokenType.rowid,
  'ROWS': TokenType.rows,
  'SAVEPOINT': TokenType.savepoint,
  'SELECT': TokenType.select,
  'SET': TokenType.set,
  'STRICT': TokenType.strict,
  'TABLE': TokenType.table,
  'TEMP': TokenType.temp,
  'TEMPORARY': TokenType.temporary,
  'THEN': TokenType.then,
  'TIES': TokenType.ties,
  'TO': TokenType.to,
  'TRANSACTION': TokenType.transaction,
  'TRIGGER': TokenType.trigger,
  'TRUE': TokenType.$true,
  'UNBOUNDED': TokenType.unbounded,
  'UNION': TokenType.union,
  'UNIQUE': TokenType.unique,
  'UPDATE': TokenType.update,
  'USING': TokenType.using,
  'VACUUM': TokenType.vacuum,
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
  'REQUIRED': TokenType.required,
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
  late int index;

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
  final int? explicitIndex;

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

    return IdentifierToken(false, span, synthetic: true);
  }
}

/// Used to represent additional information of [TokenType.numberLiteral].
///
/// For more details, see the docs on https://www.sqlite.org/syntax/numeric-literal.html
class NumericToken extends Token {
  /// The digits before the decimal point, or null if this numeric token was
  /// written in hexadecimal notation or started with a decimal point.
  String? digitsBeforeDecimal;

  /// Whether this token has a decimal point in it.
  bool hasDecimalPoint;

  /// The digits after the decimal point, or null if this numeric token doesn't
  /// have anything after its decimal point.
  String? digitsAfterDecimal;

  /// The hexadecimal digits of this token, or null if this token was not in
  /// hex notation.
  String? hexDigits;

  /// An exponent to the base of ten.
  ///
  /// For instance, `2E-2` has an [exponent] of `-2`.
  final int? exponent;

  NumericToken(
    FileSpan span, {
    this.digitsBeforeDecimal,
    this.hasDecimalPoint = false,
    this.digitsAfterDecimal,
    this.hexDigits,
    this.exponent,
  }) : super(TokenType.numberLiteral, span);

  /// The numeric literal represented by this token.
  num get parsedNumber {
    if (hexDigits != null) {
      return int.parse(hexDigits!, radix: 16);
    }

    final beforeDecimal =
        digitsBeforeDecimal != null ? int.parse(digitsBeforeDecimal!) : 0;

    num number;

    if (!hasDecimalPoint) {
      number = beforeDecimal;
    } else if (digitsAfterDecimal != null) {
      number = beforeDecimal + double.parse('.$digitsAfterDecimal');
    } else {
      // Is of the form 3., so just infer as double
      number = beforeDecimal.toDouble();
    }

    if (exponent != null) {
      number *= pow(10, exponent!);
    }
    return number;
  }

  @visibleForTesting
  bool hasSameStructureAs(NumericToken other) {
    return other.digitsBeforeDecimal == digitsBeforeDecimal &&
        other.hasDecimalPoint == hasDecimalPoint &&
        other.digitsAfterDecimal == digitsAfterDecimal &&
        other.hexDigits == hexDigits &&
        other.exponent == exponent;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    if (hexDigits != null) {
      buffer..write('0x')..write(hexDigits);
    } else {
      if (digitsBeforeDecimal != null) {
        buffer.write(digitsBeforeDecimal);
      }
      if (hasDecimalPoint) {
        buffer.write('.');
      }
      if (digitsAfterDecimal != null) {
        buffer.write(digitsAfterDecimal);
      }

      if (exponent != null) {
        buffer..write('E')..write(exponent);
      }
    }

    return buffer.toString();
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
