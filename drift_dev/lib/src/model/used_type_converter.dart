import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:drift_dev/src/model/table.dart';
import 'package:drift_dev/src/utils/type_utils.dart';
import 'package:drift_dev/src/writer/writer.dart';

import 'column.dart';
import 'types.dart';

class UsedTypeConverter {
  /// Index of this converter in the table in which it has been created.
  int? index;

  /// The table using this type converter.
  MoorTable? table;

  /// The expression that will construct the type converter at runtime. The
  /// type converter constructed will map a [mappedType] to the [sqlType] and
  /// vice-versa.
  final String expression;

  /// The type that will be present at runtime.
  final DartType mappedType;

  /// The type that will be written to the database.
  final ColumnType sqlType;

  /// Is column nullable?
  final bool nullable;

  /// Type converters are stored as static fields in the table that created
  /// them. This will be the field name for this converter.
  String get fieldName => '\$converter$index';

  /// A Dart expression resolving to this converter.
  String get tableAndField => '${table!.entityInfoName}.$fieldName';

  UsedTypeConverter({
    required this.expression,
    required this.mappedType,
    required this.sqlType,
    required this.nullable,
  });

  bool get hasNullableDartType =>
      mappedType.nullabilitySuffix == NullabilitySuffix.question;

  factory UsedTypeConverter.forEnumColumn(DartType enumType, bool nullable) {
    if (enumType.element is! ClassElement) {
      throw InvalidTypeForEnumConverterException('Not a class', enumType);
    }

    final creatingClass = enumType.element as ClassElement;
    if (!creatingClass.isEnum) {
      throw InvalidTypeForEnumConverterException('Not an enum', enumType);
    }

    final className = creatingClass.name;
    final nullablePrefix = nullable ? 'Nullable' : '';

    return UsedTypeConverter(
      expression: 'const ${nullablePrefix}EnumIndexConverter<$className>'
          '($className.values)',
      mappedType: creatingClass.instantiate(
          typeArguments: const [],
          nullabilitySuffix:
              nullable ? NullabilitySuffix.question : NullabilitySuffix.none),
      sqlType: ColumnType.integer,
      nullable: nullable,
    );
  }

  /// A suitable typename to store an instance of the type converter used here.
  String converterNameInCode(GenerationOptions options) {
    final sqlDartType = dartTypeNames[sqlType];
    final needSuffix = nullable ? '?' : '';
    return 'TypeConverter<${mappedType.codeString(options)}, '
        '$sqlDartType$needSuffix>';
  }
}

class InvalidTypeForEnumConverterException implements Exception {
  final String reason;
  final DartType invalidType;

  InvalidTypeForEnumConverterException(this.reason, this.invalidType);

  String get errorDescription {
    return "Can't use the type ${invalidType.userVisibleName} as an enum "
        'type: $reason';
  }

  @override
  String toString() {
    return 'Invalid type for enum converter: '
        '${invalidType.userVisibleName}. Reason: $reason';
  }
}
