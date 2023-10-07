import 'package:drift/drift.dart' show DriftSqlType;

import 'column.dart';
import 'dart.dart';

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
class ColumnType {
  /// The builtin drift type used by this column.
  ///
  /// Even though it's unused there, custom types also have this field set -
  /// to [DriftSqlType.any] because drift doesn't reinterpret these values at
  /// all.
  final DriftSqlType builtin;

  /// Details about the custom type, if one is present.
  final CustomColumnType? custom;

  bool get isCustom => custom != null;

  const ColumnType.drift(this.builtin) : custom = null;

  ColumnType.custom(CustomColumnType this.custom) : builtin = DriftSqlType.any;
}

extension OperationOnTypes on HasType {
  bool get isUint8ListInDart {
    return sqlType.builtin == DriftSqlType.blob && typeConverter == null;
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

Map<DriftSqlType, DartTopLevelSymbol> dartTypeNames = Map.unmodifiable({
  DriftSqlType.bool: DartTopLevelSymbol('bool', Uri.parse('dart:core')),
  DriftSqlType.string: DartTopLevelSymbol('String', Uri.parse('dart:core')),
  DriftSqlType.int: DartTopLevelSymbol('int', Uri.parse('dart:core')),
  DriftSqlType.bigInt: DartTopLevelSymbol('BigInt', Uri.parse('dart:core')),
  DriftSqlType.dateTime: DartTopLevelSymbol('DateTime', Uri.parse('dart:core')),
  DriftSqlType.blob:
      DartTopLevelSymbol('Uint8List', Uri.parse('dart:typed_data')),
  DriftSqlType.double: DartTopLevelSymbol('double', Uri.parse('dart:core')),
  DriftSqlType.any: DartTopLevelSymbol('DriftAny', AnnotatedDartCode.drift),
});
