import 'dart:typed_data';

import 'package:drift/drift.dart';

import 'compiler.dart';

final class PostgresDialect extends DriftDialect {
  const PostgresDialect();

  @override
  KnownSqlDialect? get known => KnownSqlDialect.postgres;

  @override
  StatementCompiler createCompiler() => PostgresCompiler(this);

  @override
  SqlType<bool> get boolType => const _SimplePostgresType('BOOLEAN');

  @override
  SqlType<Uint8List> get byteArrayType =>
      const _SimplePostgresType('BYTEARRAY');

  @override
  SqlType<DateTime> get dateTimeType => const _SimplePostgresType('TIMESTAMP');

  @override
  SqlType<double> get doubleType => const _SimplePostgresType('REAL');

  @override
  SqlType<int> get intType => const _SimplePostgresType('INTEGER');

  @override
  SqlType<BigInt> get int64Type => const _SimplePostgresType('INTEGER');

  @override
  SqlType<DatabaseJson> get jsonType => const _SimplePostgresType('JSON');

  @override
  SqlType<String> get textType => const _SimplePostgresType('TEXT');
}

final class _SimplePostgresType<T extends Object> implements SqlType<T> {
  final String name;

  const _SimplePostgresType(this.name);

  @override
  T dartValue(DriftDialect dialect, Object databaseValue) => databaseValue as T;

  @override
  String sqlLiteral(DriftDialect dialect, T value) {
    throw UnimplementedError();
  }

  @override
  Object sqlParameter(DriftDialect dialect, T value) => value;

  @override
  String typeName(DriftDialect dialect) => name;
}
