import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import 'compiler.dart';
import 'types.dart';

extension DriftAnyColumnBuilder on Table {
  /// Use this as a the body of a getter to declare a column that holds
  /// arbitrary values not modified by drift at runtime.
  ///
  /// The type of this column in the schema is `ANY`, which is particularly
  /// useful for columns with an unknown type in [isStrict] tables.
  /// This type has no direct equivalent for other database engines.
  @protected
  @DriftColumnDeclarationBuilder.forCustom(SqliteDialect.anyType)
  ColumnBuilder<DriftAny> sqliteAny() => throw '';
}

/// A column storing arbitrary values using SQLite's `ANY` type.
typedef AnyColumn = SchemaColumn<DriftAny>;

final class SqliteOptions {
  final bool strictTablesByDefault;
  final bool storeDateTimesAsText;
  final bool useBinaryJsonRepresentation;

  const SqliteOptions({
    this.strictTablesByDefault = true,
    this.storeDateTimesAsText = true,
    this.useBinaryJsonRepresentation = false,
  });
}

final class SqliteDialect extends DriftDialect {
  final SqliteOptions options;

  const SqliteDialect({this.options = const SqliteOptions()});

  @override
  KnownSqlDialect? get known => KnownSqlDialect.sqlite;

  @override
  StatementCompiler createCompiler() => SqliteCompiler(this);

  @override
  SqlType<bool> get boolType => const BoolType();

  @override
  SqlType<Uint8List> get byteArrayType => blobType;

  @override
  SqlType<DateTime> get dateTimeType => const DateTimeType();

  @override
  SqlType<double> get doubleType => const DoubleType();

  @override
  SqlType<int> get intType => const IntType();

  @override
  SqlType<BigInt> get int64Type => const BigIntType();

  @override
  SqlType<DatabaseJson> get jsonType => const JsonType();

  @override
  SqlType<String> get textType => const StringType();

  /// Returns an implementation of [SqlType] that reads and writes [DriftAny]
  /// values without any further mapping.
  static SqlType<DriftAny> anyType() => const AnyType();
}
