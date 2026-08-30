import '../types.dart';
import 'expression.dart';
import 'operators.dart';

/// Defines operations on boolean values.
extension BooleanExpressionOperators on Expression<bool> {
  /// Negates this boolean expression. The returned expression is true if
  /// `this` is false, and vice versa.
  Expression<bool> not() =>
      UnaryExpression(UnaryOperator.not, this, type: BuiltinSqlType.bool);

  /// Returns an expression that is true iff both `this` and [other] are true.
  ///
  /// For a bitwise-and on two numbers, see [BitwiseInt.bitwiseAnd].
  Expression<bool> operator &(Expression<bool> other) {
    return BinaryExpression(
      this,
      BinaryOperator.and,
      other,
      type: BuiltinSqlType.bool,
    );
  }

  /// Returns an expression that is true if `this` or [other] are true.
  ///
  /// For a bitwise-or on two numbers, see [BitwiseInt.bitwiseOr].
  Expression<bool> operator |(Expression<bool> other) {
    return BinaryExpression(
      this,
      BinaryOperator.or,
      other,
      type: BuiltinSqlType.bool,
    );
  }
}
