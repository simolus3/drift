import 'package:drift_core/src/builder/context.dart';

import 'expression.dart';

class Constant<T> extends Expression<T> {
  final T _value;

  Constant(this._value);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write(context.dialect.mapToSqlLiteral(_value));
  }
}
