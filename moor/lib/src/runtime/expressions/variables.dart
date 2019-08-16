import 'dart:typed_data';

import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/expressions/expression.dart';
import 'package:moor/src/types/sql_types.dart';

/// An expression that represents the value of a dart object encoded to sql
/// using prepared statements.
class Variable<T, S extends SqlType<T>> extends Expression<T, S> {
  final T value;

  const Variable(this.value);

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

  /// Creates a variable that holds the specified data blob.
  static Variable<Uint8List, BlobType> withBlob(Uint8List value) {
    return Variable(value);
  }

  /// Creates a variable that holds the specified floating point value.
  static Variable<double, RealType> withReal(double value) {
    return Variable(value);
  }

  /// Maps [value] to something that should be understood by the underlying
  /// database engine. For instance, a [DateTime] will me mapped to its unix
  /// timestamp.
  dynamic mapToSimpleValue(GenerationContext context) {
    return _mapToSimpleValue(context, value);
  }

  @override
  void writeInto(GenerationContext context) {
    _writeVariableIntoContext(context, value);
  }
}

/// An expression that represents the value of a dart object encoded to sql
/// by writing them into the sql statements. For most cases, consider using
/// [Variable] instead.
class Constant<T, S extends SqlType<T>> extends Expression<T, S> {
  const Constant(this.value);

  final T value;

  @override
  final bool isLiteral = true;

  @override
  void writeInto(GenerationContext context) {
    // Instead of writing string literals (which we don't support because of
    // possible sql injections), just write the variable.
    if (value is String) {
      _writeVariableIntoContext(context, value);
    } else {
      final type = context.typeSystem.forDartType<T>();
      context.buffer.write(type.mapToSqlConstant(value));
    }
  }
}

void _writeVariableIntoContext<T>(GenerationContext context, T value) {
  if (value != null) {
    context.buffer.write('?');
    context.introduceVariable(_mapToSimpleValue<T>(context, value));
  } else {
    context.buffer.write('NULL');
  }
}

dynamic _mapToSimpleValue<T>(GenerationContext context, T value) {
  final type = context.typeSystem.forDartType<T>();
  return type.mapToSqlVariable(value);
}
