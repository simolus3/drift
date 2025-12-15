import 'expression.dart';
import 'operators.dart';

/// Extensions providing bitwise operators [~], on integer expressions.
extension BitwiseInt on Expression<int> {
  /// Flips all bits in this value (turning `0` to `1` and vice-versa) and
  /// returns the result.
  Expression<int> operator ~() {
    return UnaryExpression(UnaryOperator.bitwiseNot, this);
  }

  /// Returns the bitwise-or operation between `this` and [other].
  Expression<int> bitwiseOr(Expression<int> other) {
    return BinaryExpression(this, BinaryOperator.bitwiseOr, other);
  }

  /// Returns the bitwise-and operation between `this` and [other].
  Expression<int> bitwiseAnd(Expression<int> other) {
    return BinaryExpression(this, BinaryOperator.bitwiseAnd, other);
  }
}

/// Extensions providing bitwise operators [~], on integer expressions that are
/// represented as a Dart [BigInt].
extension BitwiseBigInt on Expression<BigInt> {
  /// Flips all bits in this value (turning `0` to `1` and vice-versa) and
  /// returns the result.
  ///
  /// Note that, just like [BitwiseInt], this still operates on 64-bit integers
  /// in SQL. The [BigInt] type on the expression only tells drift that the
  /// result should be integerpreted as a big integer, which is primarily useful
  /// on the web where large values cannot be stored in an [int].
  Expression<BigInt> operator ~() {
    return UnaryExpression(UnaryOperator.bitwiseNot, this);
  }

  /// Returns the bitwise-or operation between `this` and [other].
  ///
  /// Note that, just like [BitwiseInt], this still operates on 64-bit integers
  /// in SQL. The [BigInt] type on the expression only tells drift that the
  /// result should be integerpreted as a big integer, which is primarily useful
  /// on the web where large values cannot be stored in an [int].
  Expression<BigInt> bitwiseOr(Expression<BigInt> other) {
    return BinaryExpression(this, BinaryOperator.bitwiseOr, other);
  }

  /// Returns the bitwise-and operation between `this` and [other].
  ///
  /// Note that, just like [BitwiseInt], this still operates on 64-bit integers
  /// in SQL. The [BigInt] type on the expression only tells drift that the
  /// result should be integerpreted as a big integer, which is primarily useful
  /// on the web where large values cannot be stored in an [int].
  Expression<BigInt> bitwiseAnd(Expression<BigInt> other) {
    return BinaryExpression(this, BinaryOperator.bitwiseAnd, other);
  }
}
