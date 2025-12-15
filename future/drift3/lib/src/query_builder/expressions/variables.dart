// ignoring the lint because we can't have parameterized factories
// ignore_for_file: prefer_constructors_over_static_methods

import 'dart:typed_data';

import '../../connection/connection.dart';
import '../compiler.dart';
import '../dialect.dart';
import '../types.dart';
import 'expression.dart';

/// An expression that represents the value of a dart object encoded to sql
/// using prepared statements.
final class Variable<T extends Object> extends Expression<T> {
  /// The Dart value that will be sent to the database
  final T? value;
  final PhysicalSqlType<T> Function(DriftDialect)? _resolveType;

  @override
  Precedence get precedence => Precedence.primary;

  @override
  int get hashCode => value.hashCode;

  /// Constructs a new variable from the [value].
  const Variable(this.value, [this._resolveType]);

  /// Creates a variable that holds the specified boolean.
  static Variable<bool> withBool(bool value) {
    return Variable(value);
  }

  /// Creates a variable that holds the specified int.
  static Variable<int> withInt(int value) {
    return Variable(value);
  }

  /// Creates a variable that holds the specified BigInt.
  static Variable<BigInt> withBigInt(BigInt value) {
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

  @override
  String toString() => 'Variable($value)';

  @override
  bool operator ==(Object other) {
    return other is Variable && other.value == value;
  }

  @override
  PhysicalSqlType<T> resolveType(DriftDialect dialect) {
    if (_resolveType case final resolve?) {
      return resolve(dialect);
    }

    final builtin =
        BuiltinDriftType.forType<T>() ??
        BuiltinDriftType.forValue(value) ??
        BuiltinDriftType.text;
    return (builtin as BuiltinDriftType<T>).resolveIn(dialect);
  }

  @override
  void compileWith(StatementCompiler compiler) {
    return compiler.addVariable(this);
  }

  /// Resolves the type of this variable and uses that type implementation to
  /// map [value] into the underlying representation for the SQL implementation.
  MappedValue resolveValue(DriftDialect dialect) {
    return MappedValue.map(resolveType(dialect), value);
  }
}

/// An expression that represents the value of a dart object encoded to sql
/// by writing them into the sql statements. For most cases, consider using
/// [Variable] instead.
final class Literal<T extends Object> extends Expression<T> {
  /// The value that will be converted to an sql literal.
  final T? value;
  final PhysicalSqlType<T> Function(DriftDialect)? _resolveType;

  /// Constructs a new SQL literal holding the [value].
  const Literal(this.value, [this._resolveType]);

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
  PhysicalSqlType<T> resolveType(DriftDialect dialect) {
    if (_resolveType case final resolve?) {
      return resolve(dialect);
    }

    final builtin =
        BuiltinDriftType.forType<T>() ??
        BuiltinDriftType.forValue(value) ??
        BuiltinDriftType.text;
    return (builtin as BuiltinDriftType<T>).resolveIn(dialect);
  }

  @override
  void compileWith(StatementCompiler compiler) {
    return compiler.addLiteral(this);
  }
}
