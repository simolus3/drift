part of '../query_builder.dart';

/// A `text LIKE pattern` expression that will be true if the first expression
/// matches the pattern given by the second expression.
class _LikeOperator extends Expression<bool, BoolType> {
  /// The target expression that will be tested
  final Expression<String, StringType> target;

  /// The regex-like expression to test the [target] against.
  final Expression<String, StringType> regex;

  /// Perform a like operator with the target and the regex.
  _LikeOperator(this.target, this.regex);

  @override
  void writeInto(GenerationContext context) {
    target.writeInto(context);
    context.buffer.write(' LIKE ');
    regex.writeInto(context);
  }
}

/// Builtin collating functions from sqlite.
///
/// See also:
/// - https://www.sqlite.org/datatype3.html#collation
enum Collate {
  /// Instruct sqlite to compare string data using memcmp(), regardless of text
  /// encoding.
  binary,

  /// The same as [Collate.binary], except the 26 upper case characters of ASCII
  /// are folded to their lower case equivalents before the comparison is
  /// performed. Note that only ASCII characters are case folded. SQLite does
  /// not attempt to do full UTF case folding due to the size of the tables
  /// required.
  noCase,

  /// The same as [Collate.binary], except that trailing space characters are
  /// ignored.
  rTrim,
}

/// A `text COLLATE collate` expression in sqlite.
class _CollateOperator extends Expression<String, StringType> {
  /// The expression on which the collate function will be run
  final Expression inner;

  /// The [Collate] to use.
  final Collate collate;

  /// Constructs a collate expression on the [inner] expression and the
  /// [Collate].
  _CollateOperator(this.inner, this.collate);

  @override
  void writeInto(GenerationContext context) {
    inner.writeInto(context);
    context.buffer..write(' COLLATE ')..write(_operatorNames[collate]);
  }

  static const Map<Collate, String> _operatorNames = {
    Collate.binary: 'BINARY',
    Collate.noCase: 'NOCASE',
    Collate.rTrim: 'RTRIM',
  };
}
