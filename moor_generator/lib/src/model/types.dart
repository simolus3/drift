//@dart=2.9
import 'package:moor_generator/src/model/model.dart';
import 'package:moor_generator/src/utils/type_utils.dart';
import 'package:moor_generator/writer.dart';

/// Something that has a type.
///
/// This includes table and result-set column and variables.
abstract class HasType {
  /// Whether the type is nullable in Dart.
  bool get nullable;

  /// The associated sql type.
  ColumnType get type;

  /// The applied type converter, or null.
  UsedTypeConverter get typeConverter;
}

extension OperationOnTypes on HasType {
  /// Whether this type is nullable in Dart
  bool get nullableInDart {
    return nullable || typeConverter?.hasNullableDartType == true;
  }

  /// the Dart type of this column that can be handled by moors type mapping.
  /// Basically the same as [dartTypeCode], minus custom types and nullability.
  String get variableTypeName => dartTypeNames[type];

  /// The class inside the moor library that represents the same sql type as
  /// this column.
  String get sqlTypeName => sqlTypes[type];

  /// The moor Dart type that matches the type of this column.
  ///
  /// This is the same as [dartTypeCode] but without custom types.
  String variableTypeCode(
      [GenerationOptions options = const GenerationOptions()]) {
    final hasSuffix = nullableInDart && options.nnbd;
    return hasSuffix ? '$variableTypeName?' : variableTypeName;
  }

  /// The dart type that matches the values of this column. For instance, if a
  /// table has declared an `IntColumn`, the matching dart type name would be
  /// [int].
  String dartTypeCode([GenerationOptions options = const GenerationOptions()]) {
    if (typeConverter != null) {
      final needsSuffix =
          options.nnbd && nullable && !typeConverter.hasNullableDartType;
      final baseType = typeConverter.mappedType.codeString(options);

      return needsSuffix ? '$baseType?' : baseType;
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
