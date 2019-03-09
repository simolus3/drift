import 'package:moor/moor.dart';
import 'expression.dart';

abstract class IntExpression extends Expression<int, IntType>
    with ComparableExpr {}

mixin ComparableExpr<DT, ST extends SqlType<DT>> on Expression<DT, ST> {
  /// Returns an expression that is true if this expression is strictly bigger
  /// than the other expression.
  Expression<bool, BoolType> isBiggerThan(Expression<DT, ST> other) {
    return Comparison(this, ComparisonOperator.more, other);
  }

  /// Returns an expression that is true if this expression is strictly bigger
  /// than the other value.
  Expression<bool, BoolType> isBiggerThanValue(DT other) =>
      isBiggerThan(Variable(other));

  /// Returns an expression that is true if this expression is bigger than or
  /// equal to he other expression.
  Expression<bool, BoolType> isBiggerOrEqual(Expression<DT, ST> other) {
    return Comparison(this, ComparisonOperator.moreOrEqual, other);
  }

  /// Returns an expression that is true if this expression is bigger than or
  /// equal to he other value.
  Expression<bool, BoolType> isBiggerOrEqualValue(DT other) =>
      isBiggerOrEqual(Variable(other));

  /// Returns an expression that is true if this expression is strictly smaller
  /// than the other expression.
  Expression<bool, BoolType> isSmallerThan(Expression<DT, ST> other) {
    return Comparison(this, ComparisonOperator.less, other);
  }

  /// Returns an expression that is true if this expression is strictly smaller
  /// than the other value.
  Expression<bool, BoolType> isSmallerThanValue(DT other) =>
      isSmallerThan(Variable(other));

  /// Returns an expression that is true if this expression is smaller than or
  /// equal to he other expression.
  Expression<bool, BoolType> isSmallerOrEqual(Expression<DT, ST> other) {
    return Comparison(this, ComparisonOperator.lessOrEqual, other);
  }

  /// Returns an expression that is true if this expression is smaller than or
  /// equal to he other value.
  Expression<bool, BoolType> isSmallerOrEqualValue(DT other) =>
      isSmallerOrEqual(Variable(other));
}
