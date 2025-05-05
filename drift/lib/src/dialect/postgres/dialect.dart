import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../common_types.dart';
import 'compiler.dart';

final class PostgresDialect extends DriftDialect {
  const PostgresDialect();

  @override
  KnownSqlDialect? get known => KnownSqlDialect.postgres;

  @override
  StatementCompiler createCompiler() => PostgresCompiler(this);

  @override
  SqlType<bool> get boolType => const _SafeSqlLiteralType('boolean');

  @override
  SqlType<Uint8List> get byteArrayType => blobType;

  @override
  SqlType<DateTime> get dateTimeType => const _TimestampType();

  @override
  SqlType<double> get doubleType => const CommonDoubleType();

  @override
  SqlType<int> get intType => const _SafeSqlLiteralType('INTEGER');

  @override
  SqlType<BigInt> get int64Type => const _SafeSqlLiteralType('INTEGER');

  @override
  SqlType<DatabaseJson> get jsonType => const _SimplePostgresType('JSON');

  @override
  SqlType<String> get textType => const CommonTextType();
}

const blobType = CommonByteArrayType('bytea');

final class _SimplePostgresType<T extends Object> implements SqlType<T> {
  final String name;

  const _SimplePostgresType(this.name);

  @override
  T dartValue(DriftDialect dialect, Object databaseValue) => databaseValue as T;

  @override
  String sqlLiteral(DriftDialect dialect, T value) {
    throw UnimplementedError(name);
  }

  @override
  Object sqlParameter(DriftDialect dialect, T value) => value;

  @override
  String typeName(DriftDialect dialect) => name;
}

final class _SafeSqlLiteralType<T extends Object>
    extends _SimplePostgresType<T> {
  const _SafeSqlLiteralType(super.name);

  @override
  String sqlLiteral(DriftDialect dialect, T value) {
    return value.toString();
  }
}

final class _TimestampType extends _SimplePostgresType<DateTime> {
  const _TimestampType() : super('TIMESTAMP');

  @override
  String sqlLiteral(DriftDialect dialect, DateTime value) {
    return 'TIMESTAMP ${BuiltinDriftType.text.sqlLiteral(dialect, value.toIso8601String())}';
  }
}
