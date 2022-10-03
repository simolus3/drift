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

  /// The moor Dart type that matches the type of this column.
  ///
  /// This is the same as [dartTypeCode] but without custom types.
  String variableTypeCode({bool? nullable}) {
    if (isArray) {
      return 'List<${innerColumnType(nullable: nullable ?? this.nullable)}>';
    } else {
      return innerColumnType(nullable: nullable ?? this.nullable);
    }
  }

  String innerColumnType({bool nullable = false}) {
    String code;

    switch (sqlType) {
      case DriftSqlType.int:
        code = 'int';
        break;
      case DriftSqlType.bigInt:
        code = 'BigInt';
        break;
      case DriftSqlType.string:
        code = 'String';
        break;
      case DriftSqlType.bool:
        code = 'bool';
        break;
      case DriftSqlType.dateTime:
        code = 'DateTime';
        break;
      case DriftSqlType.blob:
        code = 'Uint8List';
        break;
      case DriftSqlType.double:
        code = 'double';
        break;
    }

    return nullable ? '$code?' : code;
  }
}

Map<DriftSqlType, DartTopLevelSymbol> dartTypeNames = Map.unmodifiable({
  DriftSqlType.bool: DartTopLevelSymbol('bool', Uri.parse('dart:core')),
  DriftSqlType.string: DartTopLevelSymbol('String', Uri.parse('dart:core')),
  DriftSqlType.int: DartTopLevelSymbol('int', Uri.parse('dart:core')),
  DriftSqlType.bigInt: DartTopLevelSymbol('BigInt', Uri.parse('dart:core')),
  DriftSqlType.dateTime: DartTopLevelSymbol('DateTime', Uri.parse('dart:core')),
  DriftSqlType.blob: DartTopLevelSymbol('Uint8List', Uri.parse('dart:convert')),
  DriftSqlType.double: DartTopLevelSymbol('double', Uri.parse('dart:core')),
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
