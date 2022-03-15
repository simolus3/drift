import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:drift_dev/src/model/model.dart';
import 'package:drift_dev/src/utils/type_utils.dart';
import 'package:drift_dev/writer.dart';

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
  ColumnType get type;

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
      if (withNullability) {
        switch (nullabilitySuffix) {
          case NullabilitySuffix.question:
            return '$source?';
          case NullabilitySuffix.star:
            return '$source*';
          case NullabilitySuffix.none:
            return source;
        }
      }
    }

    return type.getDisplayString(withNullability: withNullability);
  }

  String codeString([GenerationOptions options = const GenerationOptions()]) {
    if (overiddenSource != null) {
      if (nullabilitySuffix == NullabilitySuffix.star) {
        return getDisplayString(withNullability: false);
      }
      return getDisplayString(withNullability: options.nnbd);
    } else {
      return type.codeString(options);
    }
  }
}

extension OperationOnTypes on HasType {
  /// Whether this type is nullable in Dart
  bool get nullableInDart {
    return (nullable && !isArray) || typeConverter?.hasNullableDartType == true;
  }

  /// the Dart type of this column that can be handled by moors type mapping.
  /// Basically the same as [dartTypeCode], minus custom types and nullability.
  String get variableTypeName => dartTypeNames[type]!;

  /// The class inside the moor library that represents the same sql type as
  /// this column.
  String get sqlTypeName => sqlTypes[type]!;

  /// The moor Dart type that matches the type of this column.
  ///
  /// This is the same as [dartTypeCode] but without custom types.
  String variableTypeCode(
      [GenerationOptions options = const GenerationOptions()]) {
    if (isArray) {
      return 'List<${variableTypeCodeWithoutArray(options)}>';
    } else {
      return variableTypeCodeWithoutArray(options);
    }
  }

  String variableTypeCodeWithoutArray(
      [GenerationOptions options = const GenerationOptions()]) {
    final innerHasSuffix = nullable && options.nnbd;
    return innerHasSuffix ? '$variableTypeName?' : variableTypeName;
  }

  /// The dart type that matches the values of this column. For instance, if a
  /// table has declared an `IntColumn`, the matching dart type name would be
  /// [int].
  String dartTypeCode([GenerationOptions options = const GenerationOptions()]) {
    final converter = typeConverter;
    if (converter != null) {
      final needsSuffix = options.nnbd &&
          (options.nullAwareTypeConverters
              ? converter.hasNullableDartType
              : (nullable && !converter.hasNullableDartType));
      final baseType = converter.mappedType.codeString(options);

      final inner = needsSuffix ? '$baseType?' : baseType;
      return isArray ? 'List<$inner>' : inner;
    }

    return variableTypeCode(options);
  }
}

const Map<ColumnType, String> dartTypeNames = {
  ColumnType.boolean: 'bool',
  ColumnType.text: 'String',
  ColumnType.integer: 'int',
  ColumnType.datetime: 'DateTime',
  ColumnType.blob: 'Uint8List',
  ColumnType.real: 'double',
};

/// Maps from a column type to code that can be used to create a variable of the
/// respective type.
const Map<ColumnType, String> createVariable = {
  ColumnType.boolean: 'Variable.withBool',
  ColumnType.text: 'Variable.withString',
  ColumnType.integer: 'Variable.withInt',
  ColumnType.datetime: 'Variable.withDateTime',
  ColumnType.blob: 'Variable.withBlob',
  ColumnType.real: 'Variable.withReal',
};

const Map<ColumnType, String> sqlTypes = {
  ColumnType.boolean: 'BoolType',
  ColumnType.text: 'StringType',
  ColumnType.integer: 'IntType',
  ColumnType.datetime: 'DateTimeType',
  ColumnType.blob: 'BlobType',
  ColumnType.real: 'RealType',
};
