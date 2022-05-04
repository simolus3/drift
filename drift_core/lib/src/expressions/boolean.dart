import 'common.dart';
import 'expression.dart';

extension BooleanExpressions on Expression<bool> {
  Expression<bool> operator &(Expression<bool> other) {
    return BinaryExpression(this, '&', other, precedence: Precedence.and);
  }

  Expression<bool> operator |(Expression<bool> other) {
    return BinaryExpression(this, '|', other, precedence: Precedence.or);
  }
}
