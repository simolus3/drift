import 'package:drift_core/src/builder/context.dart';
import 'package:meta/meta.dart';

import 'expression.dart';

@internal
class BinaryExpression<T> extends Expression<T> {
  final Expression<Object?> _left, _right;
  final String _operator;

  BinaryExpression(
    this._left,
    this._operator,
    this._right, {
    Precedence precedence = Precedence.unknown,
  }) : super(precedence: precedence);

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, _left);
    context.buffer.write(' $_operator ');
    writeInner(context, _right);
  }
}
