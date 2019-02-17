import 'package:sally/sally.dart';
import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';

Expression<BoolType> isNull(Expression inner) => _NullCheck(inner, true);
Expression<BoolType> isNotNull(Expression inner) => _NullCheck(inner, false);

class _NullCheck extends Expression<BoolType> {

  final Expression _inner;
  final bool _isNull;

  _NullCheck(this._inner, this._isNull);

  @override
  void writeInto(GenerationContext context) {
    _inner.writeInto(context);

    context.buffer.write(' IS ');
    if (!_isNull) {
      context.buffer.write('NOT ');
    }
    context.buffer.write('NULL');
  }

}