import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:drift_dev/src/model/table.dart';
import 'package:drift_dev/src/utils/type_utils.dart';

import 'types.dart';

class UsedTypeConverter {
  /// Index of this converter in the table in which it has been created.
  int? index;

  /// The table using this type converter.
  DriftTable? table;

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

  /// Whether this type converter can be skipped for `null` values.
  ///
  /// This applies to type converters with a non-nullable Dart and SQL type if
  /// the column is nullable. For those converters, drift maps `null` to `null`
  /// without calling the type converter at all.
  ///
  /// For nullable columns, this is implemented by wrapping it in a
  /// `NullAwareTypeConverter` in the generated code for table classes. For
  /// nullable references to non-nullable columns (e.g. from outer joins), this
  /// is done with static helper methods on `NullAwareTypeConverter`.
  final bool canBeSkippedForNulls;

  /// Type converters are stored as static fields in the table that created
  /// them. This will be the field name for this converter.
  String get fieldName => '\$converter$index';

  /// If this converter [canBeSkippedForNulls] and is applied to a nullable
  /// column, drift generates a new wrapped type converter which will deal with
  /// `null` values.
  /// That converter is stored in this field.
  String get nullableFieldName => '${fieldName}n';

  /// A Dart expression resolving to this converter.
  String tableAndField({bool forNullableColumn = false}) {
    final field = canBeSkippedForNulls && forNullableColumn
        ? nullableFieldName
        : fieldName;

    return '${table!.entityInfoName}.$field';
  }

  UsedTypeConverter({
    required this.expression,
    required this.dartType,
    required this.sqlType,
    required this.dartTypeIsNullable,
    required this.sqlTypeIsNullable,
    this.alsoAppliesToJsonConversion = false,
    this.canBeSkippedForNulls = false,
  });

  factory UsedTypeConverter.forEnumColumn(
    DartType enumType,
    TypeProvider typeProvider,
  ) {
    if (enumType is! InterfaceType) {
      throw InvalidTypeForEnumConverterException('Not a class', enumType);
    }

    final creatingClass = enumType.element2;
    if (creatingClass is! EnumElement) {
      throw InvalidTypeForEnumConverterException('Not an enum', enumType);
    }

    final className = creatingClass.name;

    final expression = 'EnumIndexConverter<$className>($className.values)';

    return UsedTypeConverter(
      expression: 'const $expression',
      dartType: DriftDartType(
        type: creatingClass.instantiate(
            typeArguments: const [], nullabilitySuffix: NullabilitySuffix.none),
        overiddenSource: creatingClass.name,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
      canBeSkippedForNulls: true,
      sqlTypeIsNullable: false,
      dartTypeIsNullable: false,
      sqlType: typeProvider.intType,
    );
  }

  bool mapsToNullableDart(bool nullableInSql) {
    return dartTypeIsNullable || (canBeSkippedForNulls && nullableInSql);
  }

  String dartTypeCode(bool nullableInSql) {
    var type = dartType.codeString();
    if (canBeSkippedForNulls && nullableInSql) type += '?';

    return type;
  }

  /// A suitable typename to store an instance of the type converter used here.
  String converterNameInCode({bool makeNullable = false}) {
    var sqlDartType = sqlType.getDisplayString(withNullability: true);
    if (makeNullable) sqlDartType += '?';

    final className =
        alsoAppliesToJsonConversion ? 'JsonTypeConverter' : 'TypeConverter';

    return '$className<${dartTypeCode(makeNullable)}, $sqlDartType>';
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
