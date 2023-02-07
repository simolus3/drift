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
  DriftSqlType get sqlType;

  /// The applied type converter, or null if no type converter has been applied
  /// to this column.
  AppliedTypeConverter? get typeConverter;
}

extension OperationOnTypes on HasType {
  bool get isUint8ListInDart =>
      sqlType == DriftSqlType.blob && typeConverter == null;

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

/// Maps from a column type to code that can be used to create a variable of the
/// respective type.
const Map<DriftSqlType, String> createVariable = {
  DriftSqlType.bool: 'Variable.withBool',
  DriftSqlType.string: 'Variable.withString',
  DriftSqlType.int: 'Variable.withInt',
  DriftSqlType.bigInt: 'Variable.withBigInt',
  DriftSqlType.dateTime: 'Variable.withDateTime',
  DriftSqlType.blob: 'Variable.withBlob',
  DriftSqlType.double: 'Variable.withReal',
};
