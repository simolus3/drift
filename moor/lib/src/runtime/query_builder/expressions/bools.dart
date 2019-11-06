part of '../query_builder.dart';

/// Returns an expression that is true iff both [a] and [b] are true.
///
/// This is now deprecated. Instead of `and(a, b)`, use `a & b`.
@Deprecated('Use the operator on BooleanExpressionOperators instead')
Expression<bool, BoolType> and(
        Expression<bool, BoolType> a, Expression<bool, BoolType> b) =>
    _AndExpression(a, b);

/// Returns an expression that is true iff [a], [b] or both are true.
///
/// This is now deprecated. Instead of `or(a, b)`, use `a | b`;
@Deprecated('Use the operator on BooleanExpressionOperators instead')
Expression<bool, BoolType> or(
        Expression<bool, BoolType> a, Expression<bool, BoolType> b) =>
    _OrExpression(a, b);

/// Returns an expression that is true iff [a] is not true.
///
/// This is now deprecated. Instead of `not(a)`, prefer to use `a.not()` now.
@Deprecated('Use BooleanExpressionOperators.not() as a extension instead')
Expression<bool, BoolType> not(Expression<bool, BoolType> a) =>
    _NotExpression(a);

/// Defines operations on boolean values.
extension BooleanExpressionOperators on Expression<bool, BoolType> {
  /// Negates this boolean expression. The returned expression is true if
  /// `this` is false, and vice versa.
  Expression<bool, BoolType> not() => _NotExpression(this);

  /// Returns an expression that is true iff both `this` and [other] are true.
  Expression<bool, BoolType> operator &(Expression<bool, BoolType> other) {
    return _AndExpression(this, other);
  }

  /// Returns an expression that is true if `this` or [other] are true.
  Expression<bool, BoolType> operator |(Expression<bool, BoolType> other) {
    return _OrExpression(this, other);
  }
}

class _AndExpression extends _InfixOperator<bool, BoolType> {
  @override
  Expression<bool, BoolType> left, right;

  @override
  final String operator = 'AND';

  _AndExpression(this.left, this.right);
}

class _OrExpression extends _InfixOperator<bool, BoolType> {
  @override
  Expression<bool, BoolType> left, right;

  @override
  final String operator = 'OR';

  _OrExpression(this.left, this.right);
}

class _NotExpression extends Expression<bool, BoolType> {
  Expression<bool, BoolType> inner;

  _NotExpression(this.inner);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('NOT ');
    inner.writeInto(context);
  }
}
