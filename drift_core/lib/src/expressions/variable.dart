import 'package:drift_core/src/builder/context.dart';

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

    String variableName;

    if (context.shouldUseIndexedVariables) {
      variableName = context.dialect.indexedVariable(context.nextVariableIndex);
    } else {
      variableName = context.dialect.indexedVariable(null);
    }

    context.buffer.write(variableName);
    context.introduceVariable(
        this, variableName, context.dialect.mapToSqlVariable(_value));
  }
}
