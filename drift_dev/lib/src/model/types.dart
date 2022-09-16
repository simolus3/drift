import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:drift_dev/src/model/model.dart';
import 'package:drift_dev/src/utils/type_utils.dart';

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
  DriftSqlType get type;

  /// The applied type converter, or null.
  UsedTypeConverter? get typeConverter;
}

class DriftDartType {
  final DartType type;
  final String? overiddenSource;
  final NullabilitySuffix nullabilitySuffix;

  const DriftDartType({
    required this.type,
    this.overiddenSource,
    required this.nullabilitySuffix,
  });

  factory DriftDartType.of(DartType type) {
    return DriftDartType(
      type: type,
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }

  String getDisplayString({required bool withNullability}) {
    final source = overiddenSource;
    if (source != null) {
      return source;
    }

    return type.getDisplayString(withNullability: withNullability);
  }

  String codeString() {
    if (overiddenSource != null) {
      if (nullabilitySuffix == NullabilitySuffix.star) {
        return getDisplayString(withNullability: false);
      }
      return getDisplayString(withNullability: true);
    } else {
      return type.codeString();
    }
  }
}

extension OperationOnTypes on HasType {
  bool get isUint8ListInDart =>
      type == DriftSqlType.blob && typeConverter == null;

  /// Whether this type is nullable in Dart
  bool get nullableInDart {
    if (isArray) return false; // Is a List<Something> in Dart, not nullable

    final converter = typeConverter;
    if (converter != null) {
      return converter.mapsToNullableDart(nullable);
    }

    return nullable;
  }

  /// the Dart type of this column that can be handled by moors type mapping.
  /// Basically the same as [dartTypeCode], minus custom types and nullability.
  String get variableTypeName => dartTypeNames[type]!;

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

    switch (type) {
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

  /// The dart type that matches the values of this column. For instance, if a
  /// table has declared an `IntColumn`, the matching dart type name would be
  /// [int].
  String dartTypeCode() {
    final converter = typeConverter;
    if (converter != null) {
      var inner = converter.dartType.codeString();
      if (converter.canBeSkippedForNulls && nullable) inner += '?';
      return isArray ? 'List<$inner>' : inner;
    }

    return variableTypeCode();
  }
}

const Map<DriftSqlType, String> dartTypeNames = {
  DriftSqlType.bool: 'bool',
  DriftSqlType.string: 'String',
  DriftSqlType.int: 'int',
  DriftSqlType.bigInt: 'BigInt',
  DriftSqlType.dateTime: 'DateTime',
  DriftSqlType.blob: 'Uint8List',
  DriftSqlType.double: 'double',
};

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
