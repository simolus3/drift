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

  /// The "Dart" type of this type converter.
  ///
  /// Note that, even when this type is non-nullable, the actual type used on
  /// data classes and companions can still be nullable. For instance, when a
  /// non-nullable type converter is applied to a nullable column, drift will
  /// implicitly map `null` values to `null` without invoking the converter.
  final DriftDartType dartType;

  /// The "SQL" type of this type converter. This is the type used to represent
  /// mapped values in the database.
  final DartType sqlType;

  /// Whether the Dart-value output of this type converter is nullable.
  ///
  /// In other words, [dartType] is potentially nullable.
  final bool dartTypeIsNullable;

  /// Whether the SQL-value output of this type converter is nullable.
  ///
  /// In other words, [sqlType] is potentially nullable.
  final bool sqlTypeIsNullable;

  /// Whether this type converter should also be used in the generated JSON
  /// serialization.
  final bool alsoAppliesToJsonConversion;

  /// Whether this type converter should be skipped for `null` values.
  ///
  /// This applies to type converters with a non-nullable Dart and SQL type if
  /// the column is nullable. For those converters, drift maps `null` to `null`
  /// without calling the type converter at all.
  ///
  /// This is implemented by wrapping it in a `NullAwareTypeConverter` in the
  /// generated code.
  final bool skipForNulls;

  /// Type converters are stored as static fields in the table that created
  /// them. This will be the field name for this converter.
  String get fieldName => '\$converter$index';

  /// A Dart expression resolving to this converter.
  String get tableAndField => '${table!.entityInfoName}.$fieldName';

  UsedTypeConverter({
    required this.expression,
    required this.dartType,
    required this.sqlType,
    required this.dartTypeIsNullable,
    required this.sqlTypeIsNullable,
    this.alsoAppliesToJsonConversion = false,
    this.skipForNulls = false,
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
      sqlTypeIsNullable: nullable,
      dartTypeIsNullable: nullable,
      sqlType: nullable
          ? typeProvider.intElement.instantiate(
              typeArguments: const [],
              nullabilitySuffix: NullabilitySuffix.question)
          : typeProvider.intType,
    );
  }

  bool get mapsToNullableDart => dartTypeIsNullable || skipForNulls;

  String dartTypeCode(GenerationOptions options) {
    var type = dartType.codeString(options);
    if (options.nnbd && skipForNulls) type += '?';

    return type;
  }

  /// A suitable typename to store an instance of the type converter used here.
  String converterNameInCode(GenerationOptions options) {
    var sqlDartType = sqlType.getDisplayString(withNullability: options.nnbd);
    if (options.nnbd && skipForNulls) sqlDartType += '?';

    final className =
        alsoAppliesToJsonConversion ? 'JsonTypeConverter' : 'TypeConverter';

    return '$className<${dartTypeCode(options)}, $sqlDartType>';
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
