import 'common.dart';
import 'expression.dart';

extension BooleanExpressions<Bool extends bool?> on Expression<Bool> {
  Expression<Bool> operator &(Expression<Bool> other) {
    return BinaryExpression(this, '&', other, precedence: Precedence.and);
  }

  Expression<Bool> operator |(Expression<Bool> other) {
    return BinaryExpression(this, '|', other, precedence: Precedence.or);
  }
}
