import '../compiler.dart';
import '../dialect.dart';
import '../types.dart';
import 'functions.dart';
import 'expression.dart';
import 'operators.dart';
import 'variables.dart';

/// Defines methods that operate on a column storing [String] values.
extension StringExpressionOperators on Expression<String> {
  /// Whether this column matches the given pattern. For details on what patters
  /// are valid and how they are interpreted, check out
  /// [this tutorial](http://www.sqlitetutorial.net/sqlite-like/).
  Expression<bool> like(String regex, {String? escapeChar}) {
    return likeExp(
      Variable.withString(regex),
      escape: Variable<String>(escapeChar),
    );
  }

  /// Whether this column matches the given expression. For details on what patters
  /// are valid and how they are interpreted, check out
  /// [this tutorial](http://www.sqlitetutorial.net/sqlite-like/).
  Expression<bool> likeExp(
    Expression<String> regex, {
    Expression<String>? escape,
  }) {
    return LikeExpression(this, regex, escape: escape);
  }

  /// Whether this expression contains [substring].
  ///
  /// Note that this is case-insensitive for the English alphabet only.
  ///
  /// This is equivalent to calling [like] with `%<substring>%`.
  Expression<bool> contains(String substring) {
    return like('%$substring%');
  }

  /// Uses the given [collate] sequence when comparing this column to other
  /// values.
  Expression<String> collate(Collate collate) {
    return CollateExpression._(this, collate);
  }

  /// Performs a string concatenation in sql by appending [other] to `this`.
  Expression<String> operator +(Expression<String> other) {
    return BinaryExpression(this, BinaryOperator.stringConcatenation, other);
  }

  /// Calls the sqlite function `UPPER` on `this` string. Please note that, in
  /// most sqlite installations, this only affects ascii chars.
  ///
  /// See also:
  ///  - https://www.w3resource.com/sqlite/core-functions-upper.php
  Expression<String> upper() {
    return FunctionCallExpression('UPPER', [this]);
  }

  /// Calls the sqlite function `LOWER` on `this` string. Please note that, in
  /// most sqlite installations, this only affects ascii chars.
  ///
  /// See also:
  ///  - https://www.w3resource.com/sqlite/core-functions-lower.php
  Expression<String> lower() {
    return FunctionCallExpression('LOWER', [this]);
  }

  /// Calls the sqlite function `LENGTH` on `this` string, which counts the
  /// number of characters in this string. Note that, in most sqlite
  /// installations, [length] may not support all unicode rules.
  ///
  /// See also:
  ///  - https://www.w3resource.com/sqlite/core-functions-length.php
  Expression<int> get length {
    return FunctionCallExpression('LENGTH', [this]);
  }

  /// Removes spaces from both ends of this string.
  Expression<String> trim() {
    return FunctionCallExpression('TRIM', [this]);
  }

  /// Removes spaces from the beginning of this string.
  Expression<String> trimLeft() {
    return FunctionCallExpression('LTRIM', [this]);
  }

  /// Removes spaces from the end of this string.
  Expression<String> trimRight() {
    return FunctionCallExpression('RTRIM', [this]);
  }

  /// Calls the [`substr`](https://sqlite.org/lang_corefunc.html#substr)
  /// function on this string.
  ///
  /// Note that the function has different semantics than the [String.substring]
  /// method for Dart strings - for instance, the [start] index starts at one
  /// and [length] can be negative to return a section of the string before
  /// [start].
  Expression<String> substr(int start, [int? length]) {
    return substrExpr(Literal(start), length != null ? Literal(length) : null);
  }

  /// Calls the [`substr`](https://sqlite.org/lang_corefunc.html#substr)
  /// function with arbitrary expressions as arguments.
  ///
  /// For instance, this call uses [substrExpr] to remove the last 5 characters
  /// from a column. As this depends on its [StringExpressionOperators.length],
  /// it needs to use expressions:
  ///
  /// ```dart
  /// update(table).write(TableCompanion.custom(
  ///   column: column.substrExpr(Variable(1), column.length - Variable(5))
  /// ));
  /// ```
  ///
  /// When both [start] and [length] are Dart values (e.g. [Variable]s or
  /// [Literal]s), consider using [substr] instead.
  Expression<String> substrExpr(
    Expression<int> start, [
    Expression<int>? length,
  ]) {
    return FunctionCallExpression('SUBSTR', [
      this,
      start,
      if (length != null) length,
    ]);
  }
}

/// A `LIKE` expression in SQL, with an optional `ESCAPE` clause.
final class LikeExpression extends Expression<bool> {
  /// The string being searched.
  final Expression<String> left;

  /// The text to search for.
  final Expression<String> right;

  /// An optional custom escape character for [right].
  final Expression<String>? escape;

  /// @nodoc
  LikeExpression(this.left, this.right, {required this.escape});

  @override
  int get hashCode => Object.hash(left, right, escape);

  @override
  bool operator ==(Object other) {
    return other is LikeExpression &&
        other.left == left &&
        other.right == right &&
        other.escape == escape;
  }

  @override
  Precedence get precedence => BinaryOperator.like.precedence;

  @override
  void compileWith(StatementCompiler compiler) {
    return compiler.addLikeExpression(this);
  }
}

/// An expression that changes the collation used to e.g. compare texts.
///
/// Created with [StringExpressionOperators.collate].
final class CollateExpression extends Expression<String> {
  /// The inner text expression.
  final Expression<String> source;

  /// The collation to use.
  final Collate collation;

  CollateExpression._(this.source, this.collation);

  @override
  int get hashCode => Object.hash(source, collation);

  @override
  bool operator ==(Object other) {
    return other is CollateExpression &&
        other.source == source &&
        other.collation == collation;
  }

  @override
  PhysicalSqlType<String> resolveType(DriftDialect dialect) {
    return dialect.textType;
  }

  @override
  void compileWith(StatementCompiler compiler) {
    return compiler.addCollateExpression(this);
  }
}

/// Collating functions used to compare texts in SQL.
///
/// See also:
/// - https://www.sqlite.org/datatype3.html#collation
final class Collate {
  /// The name of this collation in SQL.
  final String name;

  /// Create a collation from the [name] to use in sql.
  const Collate(this.name);

  /// Instruct sqlite to compare string data using memcmp(), regardless of text
  /// encoding.
  static const binary = Collate('BINARY');

  /// The same as [Collate.binary], except the 26 upper case characters of ASCII
  /// are folded to their lower case equivalents before the comparison is
  /// performed. Note that only ASCII characters are case folded. SQLite does
  /// not attempt to do full UTF case folding due to the size of the tables
  /// required.
  static const noCase = Collate('NOCASE');

  /// The same as [Collate.binary], except that trailing space characters are
  /// ignored.
  static const rTrim = Collate('RTRIM');
}
