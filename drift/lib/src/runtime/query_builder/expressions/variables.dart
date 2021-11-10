part of '../query_builder.dart';

// ignoring the lint because we can't have parameterized factories
// ignore_for_file: prefer_constructors_over_static_methods

/// An expression that represents the value of a dart object encoded to sql
/// using prepared statements.
class Variable<T> extends Expression<T> {
  /// The Dart value that will be sent to the database
  final T value;

  // note that we keep the identity hash/equals here because each variable would
  // get its own index in sqlite and is thus different.

  @override
  Precedence get precedence => Precedence.primary;

  @override
  int get hashCode => value.hashCode;

  /// Constructs a new variable from the [value].
  const Variable(this.value);

  /// Creates a variable that holds the specified boolean.
  static Variable<bool> withBool(bool value) {
    return Variable(value);
  }

  /// Creates a variable that holds the specified int.
  static Variable<int> withInt(int value) {
    return Variable(value);
  }

  /// Creates a variable that holds the specified string.
  static Variable<String> withString(String value) {
    return Variable(value);
  }

  /// Creates a variable that holds the specified date.
  static Variable<DateTime> withDateTime(DateTime value) {
    return Variable(value);
  }

  /// Creates a variable that holds the specified data blob.
  static Variable<Uint8List> withBlob(Uint8List value) {
    return Variable(value);
  }

  /// Creates a variable that holds the specified floating point value.
  static Variable<double> withReal(double value) {
    return Variable(value);
  }

  /// Maps [value] to something that should be understood by the underlying
  /// database engine. For instance, a [DateTime] will me mapped to its unix
  /// timestamp.
  dynamic mapToSimpleValue(GenerationContext context) {
    return context.typeSystem.mapToVariable(value);
  }

  @override
  void writeInto(GenerationContext context) {
    var explicitStart = context.explicitVariableIndex;

    var mark = '?';
    if (context.dialect == SqlDialect.postgres) {
      explicitStart = 1;
      mark = '@';
    }

    if (explicitStart != null) {
      context.buffer
        ..write(mark)
        ..write(explicitStart + context.amountOfVariables);
      context.introduceVariable(this, mapToSimpleValue(context));
    } else if (value != null) {
      context.buffer.write(mark);
      context.introduceVariable(this, mapToSimpleValue(context));
    } else {
      context.buffer.write('NULL');
    }
  }

  @override
  String toString() => 'Variable($value)';

  @override
  bool operator ==(Object other) {
    return other is Variable && other.value == value;
  }
}

/// An expression that represents the value of a dart object encoded to sql
/// by writing them into the sql statements. For most cases, consider using
/// [Variable] instead.
class Constant<T> extends Expression<T> {
  /// Constructs a new constant (sql literal) holding the [value].
  const Constant(this.value);

  @override
  Precedence get precedence => Precedence.primary;

  /// The value that will be converted to an sql literal.
  final T value;

  @override
  bool get isLiteral => true;

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write(SqlTypeSystem.mapToSqlConstant(value));
  }

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) {
    return other.runtimeType == runtimeType &&
        // ignore: test_types_in_equals
        (other as Constant<T>).value == value;
  }

  @override
  String toString() => 'Constant($value)';
}
