import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/runtime/sql_types.dart';

class Variable<T, S extends SqlType<T>> extends Expression<S> {
  final T value;

  Variable(this.value);

  @override
  void writeInto(GenerationContext context) {
    context.introduceVariable(value);
    context.buffer.write("?");
  }
}

class Constant<T, S extends SqlType<T>> extends Expression<S> {
  final T value;

  Constant(this.value);

  @override
  void writeInto(GenerationContext context) {
    final type = context.database.typeSystem.forDartType<T>();
    context.buffer.write(type.mapToSqlConstant(value));
  }
}
