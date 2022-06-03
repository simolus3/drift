import 'package:drift_core/src/builder/context.dart';

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

Expression<bool> not(Expression<bool> inner) => _NotExpression(inner);

class _NotExpression extends Expression<bool> {
  final Expression<bool> _inner;

  _NotExpression(this._inner);

  @override
  Precedence get precedence => Precedence.not;

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('NOT ');
    writeInner(context, _inner);
  }
}
