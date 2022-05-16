import 'common.dart';
import 'expression.dart';

extension BooleanExpressions on Expression<bool> {
  Expression<bool> operator &(Expression<bool> other) {
    return BinaryExpression(this, 'AND', other, precedence: Precedence.and);
  }

  Expression<bool> operator |(Expression<bool> other) {
    return BinaryExpression(this, 'OR', other, precedence: Precedence.or);
  }
}
