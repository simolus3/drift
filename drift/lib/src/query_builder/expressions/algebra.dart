import 'expression.dart';
import 'functions.dart';
import 'operators.dart';

/// Defines the `-`, `*` and `/` operators on sql expressions that support it.
extension ArithmeticExpr<DT extends num> on Expression<DT> {
  /// Performs an addition (`this` + [other]) in sql.
  Expression<DT> operator +(Expression<DT> other) {
    return BinaryExpression(this, BinaryOperator.plus, other);
  }

  /// Performs a subtraction (`this` - [other]) in sql.
  Expression<DT> operator -(Expression<DT> other) {
    return BinaryExpression(this, BinaryOperator.minus, other);
  }

  /// Returns the negation of this value.
  Expression<DT> operator -() {
    return UnaryExpression(UnaryOperator.minus, this);
  }

  /// Performs a multiplication (`this` * [other]) in sql.
  Expression<DT> operator *(Expression<DT> other) {
    return BinaryExpression(this, BinaryOperator.multiply, other);
  }

  /// Performs a division (`this` / [other]) in sql.
  Expression<DT> operator /(Expression<DT> other) {
    return BinaryExpression(this, BinaryOperator.divide, other);
  }

  /// Calculates the absolute value of this number.
  Expression<DT> abs() {
    return FunctionCallExpression('abs', [this]);
  }

  /// Rounds this expression to the nearest integer.
  Expression<int> roundToInt() {
    return FunctionCallExpression('round', [this]).cast<int>();
  }
}

/// Defines the `-`, `*` and `/` operators on sql expressions that support it.
extension ArithmeticBigIntExpr on Expression<BigInt> {
  /// Performs an addition (`this` + [other]) in sql.
  Expression<BigInt> operator +(Expression<BigInt> other) {
    return (dartCast<int>() + other.dartCast<int>()).dartCast<BigInt>();
  }

  /// Performs a subtraction (`this` - [other]) in sql.
  Expression<BigInt> operator -(Expression<BigInt> other) {
    return (dartCast<int>() - other.dartCast<int>()).dartCast<BigInt>();
  }

  /// Returns the negation of this value.
  Expression<BigInt> operator -() {
    return (-dartCast<int>()).dartCast<BigInt>();
  }

  /// Performs a multiplication (`this` * [other]) in sql.
  Expression<BigInt> operator *(Expression<BigInt> other) {
    return (dartCast<int>() * other.dartCast<int>()).dartCast<BigInt>();
  }

  /// Performs a division (`this` / [other]) in sql.
  Expression<BigInt> operator /(Expression<BigInt> other) {
    return (dartCast<int>() / other.dartCast<int>()).dartCast<BigInt>();
  }

  /// Calculates the absolute value of this number.
  Expression<BigInt> abs() {
    return dartCast<int>().abs().dartCast<BigInt>();
  }

  /// Rounds this expression to the nearest integer.
  Expression<int> roundToInt() {
    return dartCast<int>().roundToInt();
  }
}
