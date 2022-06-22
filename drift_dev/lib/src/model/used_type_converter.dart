import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:drift_dev/src/model/table.dart';
import 'package:drift_dev/src/utils/type_utils.dart';
import 'package:drift_dev/src/writer/writer.dart';

import 'types.dart';

class UsedTypeConverter {
  /// Index of this converter in the table in which it has been created.
  int? index;

  /// The table using this type converter.
  MoorTable? table;

  /// The expression that will construct the type converter at runtime. The
  /// type converter constructed will map a [dartType] to the [sqlType] and
  /// vice-versa.
  final String expression;

  /// The "Dart" type of this type converter. This is the type used on
  /// companions and data classes.
  final DriftDartType dartType;

  /// The "SQL" type of this type converter. This is the type used to represent
  /// mapped values in the database.
  final DartType sqlType;

  /// Whether the Dart-value output of this type converter is nullable.
  ///
  /// In other words, [dartType] is potentially nullable.
  final bool mapsToNullableDart;

  /// Whether the SQL-value output of this type converter is nullable.
  ///
  /// In other words, [sqlType] is potentially nullable.
  final bool mapsToNullableSql;

  /// Whether this type converter should also be used in the generated JSON
  /// serialization.
  final bool alsoAppliesToJsonConversion;

  /// Type converters are stored as static fields in the table that created
  /// them. This will be the field name for this converter.
  String get fieldName => '\$converter$index';

  /// A Dart expression resolving to this converter.
  String get tableAndField => '${table!.entityInfoName}.$fieldName';

  UsedTypeConverter({
    required this.expression,
    required this.dartType,
    required this.sqlType,
    required this.mapsToNullableDart,
    required this.mapsToNullableSql,
    this.alsoAppliesToJsonConversion = false,
  });

  factory UsedTypeConverter.forEnumColumn(
    DartType enumType,
    bool nullable,
    TypeProvider typeProvider,
  ) {
    if (enumType.element is! ClassElement) {
      throw InvalidTypeForEnumConverterException('Not a class', enumType);
    }

    final creatingClass = enumType.element as ClassElement;
    if (!creatingClass.isEnum) {
      throw InvalidTypeForEnumConverterException('Not an enum', enumType);
    }

    final className = creatingClass.name;
    final suffix =
        nullable ? NullabilitySuffix.question : NullabilitySuffix.none;

    var expression = 'EnumIndexConverter<$className>($className.values)';
    if (nullable) {
      expression = 'NullAwareTypeConverter.wrap($expression)';
    }

    return UsedTypeConverter(
      expression: 'const $expression',
      dartType: DriftDartType(
        type: creatingClass.instantiate(
            typeArguments: const [], nullabilitySuffix: NullabilitySuffix.none),
        overiddenSource: creatingClass.name,
        nullabilitySuffix: suffix,
      ),
      mapsToNullableDart: nullable,
      mapsToNullableSql: nullable,
      sqlType: nullable
          ? typeProvider.intElement.instantiate(
              typeArguments: const [],
              nullabilitySuffix: NullabilitySuffix.question)
          : typeProvider.intType,
    );
  }

  /// A suitable typename to store an instance of the type converter used here.
  String converterNameInCode(GenerationOptions options) {
    final sqlDartType = sqlType.getDisplayString(withNullability: options.nnbd);
    final className =
        alsoAppliesToJsonConversion ? 'JsonTypeConverter' : 'TypeConverter';

    return '$className<${dartType.codeString(options)}, $sqlDartType>';
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
