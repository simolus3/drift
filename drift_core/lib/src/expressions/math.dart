import '../builder/context.dart';
import 'common.dart';
import 'expression.dart';

/// Defines the `-`, `*` and `/` operators on sql expressions that support it.
extension ArithmeticExpr<T extends num> on Expression<T> {
  /// Performs an addition (`this` + [other]) in sql.
  Expression<T> operator +(Expression<T> other) {
    return BinaryExpression(this, '+', other, precedence: Precedence.plusMinus);
  }

  /// Performs a subtraction (`this` - [other]) in sql.
  Expression<T> operator -(Expression<T> other) {
    return BinaryExpression(this, '-', other, precedence: Precedence.plusMinus);
  }

  /// Returns the negation of this value.
  Expression<T> operator -() {
    return _UnaryMinus(this);
  }

  /// Performs a multiplication (`this` * [other]) in sql.
  Expression<T> operator *(Expression<T> other) {
    return BinaryExpression(this, '*', other, precedence: Precedence.mulDivide);
  }

  /// Performs a division (`this` / [other]) in sql.
  Expression<T> operator /(Expression<T> other) {
    return BinaryExpression(this, '/', other, precedence: Precedence.mulDivide);
  }

  /// Calculates the absolute value of this number.
  Expression<T> abs() {
    return FunctionCallExpression('abs', [this]);
  }

  /// Rounds this expression to the nearest integer.
  Expression<T> round() {
    return FunctionCallExpression('round', [this]);
  }
}

class _UnaryMinus<T> extends Expression<T> {
  final Expression<T> inner;

  _UnaryMinus(this.inner);

  @override
  Precedence get precedence => Precedence.unary;

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('-');
    inner.writeInto(context);
  }

  @override
  int get hashCode => Object.hash(inner, _UnaryMinus);

  @override
  bool operator ==(Object other) {
    return other is _UnaryMinus && other.inner == inner;
  }
}
