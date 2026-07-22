import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart';
// ignore: implementation_imports
import 'package:drift/src/drift3_preview/drift.dart';

import 'array_access_expression.dart';
import 'type.dart';

/// Dialect configuration for [PostgresDialect].
final class PostgresDialectOptions {
  /// Whether to use `JSONB` by default for drift JSON columns.
  final bool useJsonb;

  const PostgresDialectOptions({this.useJsonb = true});
}

/// A [DriftDialect] using postgres-compatible type mappings and SQL.
final class PostgresDialect extends DriftDialect {
  final PostgresDialectOptions _options;

  factory PostgresDialect(Map<KnownSqlDialect, Object> options) {
    final postgresOptions =
        options[KnownSqlDialect.postgres] as PostgresDialectOptions?;

    return PostgresDialect.withOptions(
      postgresOptions ?? const PostgresDialectOptions(),
    );
  }

  /// @nodoc
  const PostgresDialect.withOptions([
    this._options = const PostgresDialectOptions(),
  ]);

  @override
  PhysicalSqlType<bool> get boolType =>
      const PhysicalPostgresType(Type.boolean, 'boolean');

  @override
  PhysicalSqlType<Uint8List> get byteArrayType =>
      const PhysicalPostgresType(Type.byteArray, 'bytea');

  @override
  PhysicalSqlType<DateTime> get dateTimeType =>
      PhysicalPostgresType(Type.timestampTz, 'timestamptz');

  @override
  PhysicalSqlType<double> get doubleType =>
      const PhysicalPostgresType(Type.double, 'double');

  @override
  PhysicalSqlType<BigInt> get int64Type => const DartBigIntType();

  @override
  PhysicalSqlType<int> get intType =>
      const PhysicalPostgresType(Type.bigInteger, 'bigint');

  @override
  PhysicalSqlType<DatabaseJson> get jsonType => _options.useJsonb
      ? const PhysicalPostgresType(Type.jsonb, 'jsonb')
      : const PhysicalPostgresType(Type.json, 'json');

  @override
  KnownSqlDialect get known => KnownSqlDialect.postgres;

  @override
  PhysicalSqlType<String> get textType =>
      const PhysicalPostgresType(Type.text, 'text');

  @override
  StatementCompiler createCompiler() => PostgresSqlCompiler._(this);
}

@internal
final class PostgresSqlCompiler extends StatementCompiler {
  final PostgresDialect _dialect;

  PostgresSqlCompiler._(this._dialect);

  @override
  void addDateExtractionOperator(DateExtractionOperator<Object> e) {
    throw UnsupportedError('date extraction operators in postgres');
  }

  @override
  void addPositionalVariable(int index) {
    statement.buffer.write('\$$index');
  }

  @override
  void addUnixTimestampToDateTime(UnixTimestampToDateTime e) {
    throw UnsupportedError('mapping unix timestamps to date time');
  }

  @override
  PostgresDialect get dialect => _dialect;

  void addArrayAccessExpression(ArrayAccessExpression expr) {
    writeExpression(expr, () {
      expr.array.compileWith(this);
      statement.buffer.write('[');
      expr.index.compileWith(this);
      statement.buffer.write(']');
    });
  }
}
