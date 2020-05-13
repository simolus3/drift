import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';
import 'package:moor_generator/src/model/table.dart';

import 'column.dart';

class UsedTypeConverter {
  /// Index of this converter in the table in which it has been created.
  int index;

  /// The table using this type converter.
  MoorTable table;

  /// The expression that will construct the type converter at runtime. The
  /// type converter constructed will map a [mappedType] to the [sqlType] and
  /// vice-versa.
  final String expression;

  /// The type that will be present at runtime.
  final DartType mappedType;

  /// The type that will be written to the database.
  final ColumnType sqlType;

  /// A suitable typename to store an instance of the type converter used here.
  String get displayNameOfConverter {
    final sqlDartType = dartTypeNames[sqlType];
    return 'TypeConverter<${mappedType.getDisplayString()}, $sqlDartType>';
  }

  /// Type converters are stored as static fields in the table that created
  /// them. This will be the field name for this converter.
  String get fieldName => '\$converter$index';

  UsedTypeConverter({
    @required this.expression,
    @required this.mappedType,
    @required this.sqlType,
  });

  factory UsedTypeConverter.forEnumColumn(DartType enumType) {
    if (enumType.element is! ClassElement) {
      throw InvalidTypeForEnumConverterException('Not a class', enumType);
    }

    final creatingClass = enumType.element as ClassElement;
    if (!creatingClass.isEnum) {
      throw InvalidTypeForEnumConverterException('Not an enum', enumType);
    }

    final className = creatingClass.name;

    return UsedTypeConverter(
      expression: 'const EnumIndexConverter<$className>($className.values)',
      mappedType: enumType,
      sqlType: ColumnType.integer,
    );
  }
}

class InvalidTypeForEnumConverterException implements Exception {
  final String reason;
  final DartType invalidType;

  InvalidTypeForEnumConverterException(this.reason, this.invalidType);

  String get errorDescription {
    return "Can't use the type ${invalidType.getDisplayString()} as an enum "
        'type: $reason';
  }

  @override
  String toString() {
    return 'Invalid type for enum converter: '
        '${invalidType.getDisplayString()}. Reason: $reason';
  }
}
