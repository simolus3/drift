import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/runtime/sql_types.dart';

/// An expression that represents the value of a dart object encoded to sql
/// using prepared statements.
class Variable<T, S extends SqlType<T>> extends Expression<T, S> {
  final T value;

  Variable(this.value);

  @override
  void writeInto(GenerationContext context) {
    context.introduceVariable(value);
    context.buffer.write('?');
  }
}

/// An expression that represents the value of a dart object encoded to sql
/// by writing them into the sql statements. This is not supported for all types
/// yet as it can be vulnerable to SQL-injection attacks. Please use [Variable]
/// instead.
class Constant<T, S extends SqlType<T>> extends Expression<T, S> {
  final T value;

  Constant(this.value);

  @override
  void writeInto(GenerationContext context) {
    final type = context.database.typeSystem.forDartType<T>();
    context.buffer.write(type.mapToSqlConstant(value));
  }
}
