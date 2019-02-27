import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/runtime/sql_types.dart';

/// An expression that represents the value of a dart object encoded to sql
/// using prepared statements.
class Variable<T, S extends SqlType<T>> extends Expression<T, S> {
  final T value;

  Variable(this.value);

  /// Creates a variable that holds the specified boolean.
  static Variable<bool, BoolType> withBool(bool value) {
    return Variable(value);
  }

  /// Creates a variable that holds the specified int.
  static Variable<int, IntType> withInt(int value) {
    return Variable(value);
  }

  /// Creates a variable that holds the specified string.
  static Variable<String, StringType> withString(String value) {
    return Variable(value);
  }

  /// Creates a variable that holds the specified date.
  static Variable<DateTime, DateTimeType> withDateTime(DateTime value) {
    return Variable(value);
  }

  /// Maps [value] to something that should be understood by the underlying
  /// database engine. For instance, a [DateTime] will me mapped to its unix
  /// timestamp.
  dynamic mapToSimpleValue(GenerationContext context) {
    final type = context.database.typeSystem.forDartType<T>();
    return type.mapToSqlVariable(value);
  }

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('?');
    context.introduceVariable(mapToSimpleValue(context));
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
