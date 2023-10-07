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

class ColumnType {
  final DriftSqlType builtin;
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
