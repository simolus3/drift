import 'boolean.dart';
import '../compiler.dart';
import '../dialect.dart';
import '../types.dart';
import 'variables.dart';

/// An SQL expression, which evaluates to a value when evaluated by a database
/// engine.
abstract base class Expression<T extends Object> implements SqlComponent {
  /// Constant base constructor, allowing subclasses to be const.
  const Expression();

  /// The precedence of this expression. This can be used to automatically put
  /// parentheses around expressions as needed.
  Precedence get precedence => Precedence.unknown;

  /// Resolves the [SqlType] implementation describing the type of this
  /// expression.
  SqlType<T> resolveType(DriftDialect dialect) => dialect.resolveType<T>();

  @override
  void compileWith(StatementCompiler compiler);

  /// Chains all [predicates] together into a single expression that will
  /// evaluate to `true` iff any of the [predicates] evaluates to `true`.
  ///
  /// The [ifEmpty] value will be used when no predicates have been passed to
  /// [or]. By default, `false` is returned.
  static Expression<bool> or(
    Iterable<Expression<bool>> predicates, {
    Expression<bool> ifEmpty = const Literal(false),
  }) {
    if (predicates.isEmpty) {
      return ifEmpty;
    }

    return predicates.reduce((value, element) => value | element);
  }

  /// Chains all [predicates] together into a single expression that will
  /// evaluate to `true` iff all of the [predicates] evaluates to `true`.
  ///
  /// The [ifEmpty] value will be used when no predicates have been passed to
  /// [or]. By default, `true` is returned.
  static Expression<bool> and(
    Iterable<Expression<bool>> predicates, {
    Expression<bool> ifEmpty = const Literal(true),
  }) {
    if (predicates.isEmpty) {
      return ifEmpty;
    }

    return predicates.reduce((value, element) => value & element);
  }
}

/// Used to order the precedence of sql expressions so that we can avoid
/// unnecessary parens when generating sql statements.
enum Precedence implements Comparable<Precedence> {
  /// Precedence is unknown, assume lowest. This can be used for a
  /// [CustomExpression] to always put parens around it.
  unknown._(-1),

  /// Precedence for the `OR` operator in sql
  or._(10),

  /// Precedence for the `AND` operator in sql
  and._(11),

  /// Precedence for the unary `NOT` operator in SQL.
  not._(12),

  /// Precedence for most of the comparisons operators in sql, including
  /// equality, is (not) checks, in, like, glob, match, regexp.
  comparisonEq._(13),

  /// Precedence for the <, <=, >, >= operators in sql
  comparison._(14),

  /// Precedence for bitwise operators in sql
  bitwise._(15),

  /// Precedence for the (binary) plus and minus operators in sql
  plusMinus._(16),

  /// Precedence for the *, / and % operators in sql
  mulDivide._(17),

  /// Precedence for the || operator in sql
  stringConcatenation._(18),

  /// Precedence for unary operators in sql
  unary._(20),

  /// Precedence for postfix operators (like collate) in sql
  postfix._(21),

  /// Highest precedence in sql, used for variables and literals.
  primary._(100);

  /// Higher means higher precedence.
  final int _value;

  const Precedence._(this._value);

  @override
  int compareTo(Precedence other) {
    return _value.compareTo(other._value);
  }

  /// Returns true if this [Precedence] is lower than [other].
  bool operator <(Precedence other) => compareTo(other) < 0;

  /// Returns true if this [Precedence] is lower or equal to [other].
  bool operator <=(Precedence other) => compareTo(other) <= 0;

  /// Returns true if this [Precedence] is higher than [other].
  bool operator >(Precedence other) => compareTo(other) > 0;

  /// Returns true if this [Precedence] is higher or equal to [other].
  bool operator >=(Precedence other) => compareTo(other) >= 0;
}
