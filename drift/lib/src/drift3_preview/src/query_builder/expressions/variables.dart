// ignoring the lint because we can't have parameterized factories
// ignore_for_file: prefer_constructors_over_static_methods

import 'dart:typed_data';

import '../compiler.dart';
import '../dialect.dart';
import '../types.dart';
import 'expression.dart';

/// An expression that represents the value of a dart object encoded to sql
/// using prepared statements.
final class Variable<T extends Object> extends Expression<T> {
  /// The Dart value that will be sent to the database
  final T? value;
  final SqlType<T>? _type;

  @override
  Precedence get precedence => Precedence.primary;

  @override
  int get hashCode => value.hashCode;

  @override
  SqlType<T> get sqlType {
    if (_type case final type?) {
      return type;
    }

    final builtin =
        BuiltinDriftType.forType<T>() ??
        BuiltinDriftType.forValue(value) ??
        BuiltinDriftType.text;
    return builtin as SqlType<T>;
  }

  /// Constructs a new variable from the [value].
  const Variable(this.value, [this._type]);

  /// Creates a variable that holds the specified boolean.
  static Variable<bool> withBool(bool value) {
    return Variable(value, BuiltinDriftType.bool);
  }

  /// Creates a variable that holds the specified int.
  static Variable<int> withInt(int value) {
    return Variable(value, BuiltinDriftType.int);
  }

  /// Creates a variable that holds the specified BigInt.
  static Variable<BigInt> withBigInt(BigInt value) {
    return Variable(value, BuiltinDriftType.int64);
  }

  /// Creates a variable that holds the specified string.
  static Variable<String> withString(String value) {
    return Variable(value, BuiltinDriftType.text);
  }

  /// Creates a variable that holds the specified date.
  static Variable<DateTime> withDateTime(DateTime value) {
    return Variable(value, BuiltinDriftType.dateTime);
  }

  /// Creates a variable that holds the specified data blob.
  static Variable<Uint8List> withBlob(Uint8List value) {
    return Variable(value, BuiltinDriftType.byteArray);
  }

  /// Creates a variable that holds the specified floating point value.
  static Variable<double> withReal(double value) {
    return Variable(value, BuiltinDriftType.double);
  }

  @override
  String toString() => 'Variable($value)';

  @override
  bool operator ==(Object other) {
    return other is Variable && other.value == value;
  }

  @override
  void compileWith(StatementCompiler compiler) {
    return compiler.addVariable(this);
  }

  /// Resolves the type of this variable and uses that type implementation to
  /// map [value] into the underlying representation for the SQL implementation.
  Object? resolveValue(DriftDialect dialect) {
    return sqlType.resolveIn(dialect).sqlParameter(value);
  }

  /// Calls [Variable.resolveValue] for each variable in [variables].
  static List<Object?> resolveValues(
    DriftDialect dialect,
    Iterable<Variable> variables,
  ) {
    if (variables.isEmpty) return const [];

    final resolvedDialect = dialect;
    return [
      for (final variable in variables) variable.resolveValue(resolvedDialect),
    ];
  }
}

/// An expression that represents the value of a dart object encoded to sql
/// by writing them into the sql statements. For most cases, consider using
/// [Variable] instead.
final class Literal<T extends Object> extends Expression<T> {
  /// The value that will be converted to an sql literal.
  final T? value;
  final SqlType<T>? _type;

  /// Constructs a new SQL literal holding the [value].
  const Literal(this.value, [this._type]);

  @override
  Precedence get precedence => Precedence.primary;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Literal && other.value == value;
  }

  @override
  String toString() => 'Literal($value)';

  @override
  SqlType<T> get sqlType {
    if (_type case final type?) {
      return type;
    }

    final builtin =
        BuiltinDriftType.forType<T>() ??
        BuiltinDriftType.forValue(value) ??
        BuiltinDriftType.text;
    return builtin as SqlType<T>;
  }

  @override
  void compileWith(StatementCompiler compiler) {
    return compiler.addLiteral(this);
  }
}
