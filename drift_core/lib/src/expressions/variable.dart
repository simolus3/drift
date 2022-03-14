import 'package:drift_core/src/builder/builder.dart';

import 'expression.dart';

class Variable<T> extends Expression<T> {
  final T _value;

  const Variable(this._value) : super(precedence: Precedence.primary);

  @override
  void writeInto(GenerationContext context) {
    if (!context.supportsVariables ||
        (_value == null &&
            !context.dialect.capabilites.supportsNullVariables)) {
      // Write as a constant instead.
      context.buffer.write(context.dialect.mapToSqlLiteral(_value));
      return;
    }

    if (context.shouldUseIndexedVariables) {
      context.buffer
          .write(context.dialect.indexedVariable(context.nextVariableIndex));
    } else {
      context.buffer.write(context.dialect.indexedVariable(null));
    }
    context.introduceVariable(this, context.dialect.mapToSqlVariable(_value));
  }
}
