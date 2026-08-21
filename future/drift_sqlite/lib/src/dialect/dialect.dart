import 'dart:typed_data';

import 'package:drift3_preview/internal/common_dialect.dart';
import 'package:meta/meta.dart';
import 'package:drift3_preview/drift.dart';

import 'compiler.dart';
import 'types.dart' as types;

/// Provdes the [sqliteAny] column builder to build columns with an `ANY` type
/// in strict tables.
extension DriftAnyColumnBuilder on Table {
  /// Use this as a the body of a getter to declare a column that holds
  /// arbitrary values not modified by drift at runtime.
  ///
  /// The type of this column in the schema is `ANY`, which is particularly
  /// useful for columns with an unknown type in [isStrict] tables.
  /// This type has no direct equivalent for other database engines.
  @protected
  @DriftColumnDeclarationBuilder.forCustom(SqliteDialect.anyType)
  ColumnBuilder<types.DriftAny> sqliteAny() => throw '';
}

/// A column storing arbitrary values using SQLite's `ANY` type.
typedef AnyColumn = SchemaColumn<types.DriftAny>;

/// Options for drift's SQLite dialect implementation.
final class SqliteOptions {
  /// Whether to make all tables not explicitly overriding [Table.isStrict]
  /// `STRICT` by default.
  final bool strictTablesByDefault;

  /// Whether to use a textual representation to store date times.
  final bool storeDateTimesAsText;

  /// Whether to use the `JSONB` format to store JSON values.
  final bool useBinaryJsonRepresentation;

  /// @nodoc
  const SqliteOptions({
    this.strictTablesByDefault = true,
    this.storeDateTimesAsText = true,
    this.useBinaryJsonRepresentation = true,
  });
}

/// A [DriftDialect] implementation generating SQL text for SQLite.
final class SqliteDialect extends DriftDialect {
  /// The options to use when mapping datetime and json types.
  final SqliteOptions options;

  /// @nodoc
  const SqliteDialect.withOptions({this.options = const SqliteOptions()});

  /// A [DriftDialectFactory] opening [SqliteDialect]s.
  factory SqliteDialect(Map<KnownSqlDialect, Object> dialectOptions) {
    final options = dialectOptions[KnownSqlDialect.sqlite] as SqliteOptions?;
    return SqliteDialect.withOptions(options: options ?? const SqliteOptions());
  }

  @override
  KnownSqlDialect? get known => KnownSqlDialect.sqlite;

  @override
  StatementCompiler createCompiler() => SqliteCompiler(this);

  @override
  PhysicalSqlType<bool> get boolType => const types.BoolType();

  @override
  PhysicalSqlType<Uint8List> get byteArrayType => types.blobType;

  @override
  PhysicalSqlType<DateTime> get dateTimeType => options.storeDateTimesAsText
      ? const types.DateTimeType.text()
      : const types.DateTimeType.timestamps();

  @override
  PhysicalSqlType<double> get doubleType => const CommonDoubleType();

  @override
  PhysicalSqlType<int> get intType => types.intType;

  @override
  PhysicalSqlType<BigInt> get int64Type => types.bigIntType;

  @override
  PhysicalSqlType<DatabaseJson> get jsonType {
    return options.useBinaryJsonRepresentation
        ? const types.JsonType.asBinary()
        : const types.JsonType.asText();
  }

  @override
  PhysicalSqlType<String> get textType => types.textType;

  /// Returns an implementation of [SqlType] that reads and writes
  /// [types.DriftAny] values without any further mapping.
  static SqlType<types.DriftAny> anyType() => const types.AnyType();
}
