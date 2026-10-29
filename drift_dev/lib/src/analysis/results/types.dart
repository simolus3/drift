import 'column.dart';

/// A type supported by all dialects (DriftSqlType in drift2, BuiltinSqlType in
/// drift3).
enum BuiltinType {
  bool,
  string,
  bigInt,
  int,
  dateTime,
  blob,
  double,
  // SQLite-only in drift3.
  any,

  /// Only available in drift3.
  json,
}

/// Something that has a type.
///
/// This includes table and result-set column and variables.
abstract class HasType {
  /// Whether the type is nullable in Dart.
  bool get nullable;

  /// Whether this type is an array in sql.
  ///
  /// In this case, [nullable] refers to the inner type as arrays are always
  /// non-nullable.
  bool get isArray;

  /// The associated sql type.
  ColumnType get sqlType;

  /// The applied type converter, or null if no type converter has been applied
  /// to this column.
  AppliedTypeConverter? get typeConverter;
}

/// The underlying SQL type of a column analyzed by drift.
///
/// We distinguish between types directly supported by drift, and types that
/// are supplied by another library. Custom types can hold different Dart types,
/// but are a feature distinct from type converters: They indicate that a type
/// is directly supported by the underlying database driver, whereas a type
/// converter is a mapping done in drift.
///
/// In addition to the SQL type, we also track whether a column is nullable,
/// appears where an array is expected or has a type converter applied to it.
/// [HasType] is the interface for sql-typed elements and is implemented by
/// columns.
sealed class ColumnType {
  /// The builtin drift type used by this column.
  ///
  /// Even though it's unused there, custom types also have this field set -
  /// to [BuiltinType.any] because drift doesn't reinterpret these values at
  /// all.
  final BuiltinType builtin;

  const ColumnType._(this.builtin);

  const factory ColumnType.drift(BuiltinType builtin) = ColumnDriftType;

  const factory ColumnType.custom(CustomColumnType custom) = ColumnCustomType;
}

final class ColumnDriftType extends ColumnType {
  const ColumnDriftType(super.builtin) : super._();

  @override
  int get hashCode => builtin.hashCode;

  @override
  bool operator ==(Object other) {
    return other is ColumnDriftType && other.builtin == builtin;
  }
}

final class ColumnCustomType extends ColumnType {
  final CustomColumnType custom;

  const ColumnCustomType(this.custom) : super._(BuiltinType.any);
}

extension OperationOnTypes on HasType {
  bool get isUint8ListInDart {
    return sqlType.builtin == BuiltinType.blob && typeConverter == null;
  }

  /// Whether this type is nullable in Dart
  bool get nullableInDart {
    if (isArray) return false; // Is a List<Something> in Dart, not nullable

    final converter = typeConverter;
    if (converter != null) {
      return converter.mapsToNullableDart(nullable);
    }

    return nullable;
  }
}
