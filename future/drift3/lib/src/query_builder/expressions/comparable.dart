// ignore_for_file: invalid_use_of_protected_member

import '../compiler.dart';
import '../dialect.dart';
import '../types.dart';
import 'expression.dart';
import 'operators.dart';

/// Defines extension functions to express comparisons in sql
extension ComparableExpr<DT extends Comparable<dynamic>> on Expression<DT> {
  /// Returns an expression that is true if this expression is strictly greater
  /// than the other expression.
  Expression<bool> isGreaterThan(Expression<DT> other) {
    return BinaryExpression(this, BinaryOperator.greater, other);
  }

  /// Returns an expression that is true if this expression is strictly greater
  /// than the other value.
  Expression<bool> isGreaterThanValue(DT other) {
    return isGreaterThan(variable(other));
  }

  /// Returns an expression that is true if this expression is greater than or
  /// equal to he other expression.
  Expression<bool> isGreaterOrEqual(Expression<DT> other) {
    return BinaryExpression(this, BinaryOperator.greaterOrEqual, other);
  }

  /// Returns an expression that is true if this expression is greater than or
  /// equal to he other value.
  Expression<bool> isGreaterOrEqualValue(DT other) {
    return isGreaterOrEqual(variable(other));
  }

  /// Returns an expression that is true if this expression is strictly less
  /// than the other expression.
  Expression<bool> isLessThan(Expression<DT> other) {
    return BinaryExpression(this, BinaryOperator.less, other);
  }

  /// Returns an expression that is true if this expression is strictly smaller
  /// than the other value.
  Expression<bool> isLessThanValue(DT other) {
    return isLessThan(variable(other));
  }

  /// Returns an expression that is true if this expression is less than or
  /// equal to he other expression.
  Expression<bool> isLessOrEqual(Expression<DT> other) {
    return BinaryExpression(this, BinaryOperator.lessOrEqual, other);
  }

  /// Returns an expression that is true if this expression is less than or
  /// equal to he other value.
  Expression<bool> isLessOrEqualValue(DT other) {
    return isLessOrEqual(variable(other));
  }

  /// Returns an expression evaluating to true if this expression is between
  /// [lower] and [higher] (both inclusive).
  ///
  /// If [not] is set, the expression will be negated. To compare this
  /// expression against two values, see [isBetweenValues].
  BetweenExpression isBetween(
    Expression<DT> lower,
    Expression<DT> higher, {
    bool not = false,
  }) {
    return BetweenExpression._(
      target: this,
      lower: lower,
      higher: higher,
      not: not,
    );
  }

  /// Returns an expression evaluating to true if this expression is between
  /// [lower] and [higher] (both inclusive).
  ///
  /// If [not] is set, the expression will be negated.
  BetweenExpression isBetweenValues(DT lower, DT higher, {bool not = false}) {
    return BetweenExpression._(
      target: this,
      lower: variable(lower),
      higher: variable(higher),
      not: not,
    );
  }
}

/// A `BETWEEN` expression in SQL.
///
/// Created by [ComparableExpr.isBetween] and [ComparableExpr.isBetweenValues].
final class BetweenExpression extends Expression<bool> {
  /// The expression to be compared against [lower] and [higher].
  final Expression target;

  // https://www.sqlite.org/lang_expr.html#between
  @override
  final Precedence precedence = Precedence.comparisonEq;

  /// Whether to negate this between expression
  final bool not;

  /// The lower bound to compare [target] against.
  final Expression lower;

  /// The upper bound to compare [target] against.
  final Expression higher;

  BetweenExpression._({
    required this.target,
    required this.lower,
    required this.higher,
    this.not = false,
  });

  @override
  void compileWith(StatementCompiler compiler) {
    return compiler.addBetweenExpression(this);
  }

  @override
  PhysicalSqlType<bool> resolveType(DriftDialect dialect) => dialect.boolType;

  @override
  int get hashCode => Object.hash(target, lower, higher, not);

  @override
  bool operator ==(Object other) {
    return other is BetweenExpression &&
        other.target == target &&
        other.not == not &&
        other.lower == lower &&
        other.higher == higher;
  }
}
