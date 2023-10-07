part of '../query_builder.dart';

// ignoring the lint because we can't have parameterized factories
// ignore_for_file: prefer_constructors_over_static_methods

/// An expression that represents the value of a dart object encoded to sql
/// using prepared statements.
final class Variable<T extends Object> extends Expression<T> {
  /// The Dart value that will be sent to the database
  final T? value;
  final CustomSqlType<T>? _customType;

  // note that we keep the identity hash/equals here because each variable would
  // get its own index in sqlite and is thus different.

  @override
  Precedence get precedence => Precedence.primary;

  @override
  int get hashCode => value.hashCode;

  @override
  BaseSqlType<T> get driftSqlType => _customType ?? super.driftSqlType;

  /// Constructs a new variable from the [value].
  ///
  /// For variables of [CustomSqlType]s, the `type` can also be provided as a
  /// parameter to control how the value is mapped to SQL.
  const Variable(this.value, [this._customType]);

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

  /// Maps [value] to something that should be understood by the underlying
  /// database engine. For instance, a [DateTime] will me mapped to its unix
  /// timestamp.
  dynamic mapToSimpleValue(GenerationContext context) {
    final type = _customType;
    if (value != null && type != null) {
      return type.mapToSqlParameter(value!);
    } else {
      return context.typeMapping.mapToSqlVariable(value);
    }
  }

  @override
  void writeInto(GenerationContext context) {
    if (!context.supportsVariables ||
        // Workaround for https://github.com/simolus3/drift/issues/2441
        // Binding nulls on postgres is currently untyped which causes issues.
        (value == null && context.dialect == SqlDialect.postgres)) {
      // Write as constant instead.
      Constant<T>(value).writeInto(context);
      return;
    }

    var explicitStart = context.explicitVariableIndex;

    var mark = '?';
    var suffix = '';
    if (context.dialect == SqlDialect.postgres) {
      explicitStart = 1;
      mark = r'$';
    }

    if (explicitStart != null) {
      context.buffer
        ..write(mark)
        ..write(explicitStart + context.amountOfVariables)
        ..write(suffix);
      context.introduceVariable(
        this,
        mapToSimpleValue(context),
      );
    } else {
      context.buffer.write(mark);
      context.introduceVariable(this, mapToSimpleValue(context));
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
final class Constant<T extends Object> extends Expression<T> {
  /// The value that will be converted to an sql literal.
  final T? value;

  final CustomSqlType<T>? _customType;

  /// Constructs a new constant (sql literal) holding the [value].
  const Constant(this.value, [this._customType]);

  @override
  Precedence get precedence => Precedence.primary;

  @override
  BaseSqlType<T> get driftSqlType => _customType ?? super.driftSqlType;

  @override
  bool get isLiteral => true;

  @override
  void writeInto(GenerationContext context) {
    final type = _customType;
    if (value != null && type != null) {
      context.buffer.write(type.mapToSqlLiteral(value!));
    } else {
      context.buffer.write(context.typeMapping.mapToSqlLiteral(value));
    }
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
