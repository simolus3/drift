import 'package:built_value/built_value.dart';
import 'package:moor_generator/src/model/used_type_converter.dart';

part 'specified_column.g.dart';

enum ColumnType { integer, text, boolean, datetime, blob, real }

/// Name of a column. Contains additional info on whether the name was chosen
/// implicitly (based on the dart getter name) or explicitly (via an named())
/// call in the column builder dsl.
abstract class ColumnName implements Built<ColumnName, ColumnNameBuilder> {
  /// A column name is implicit if it has been looked up with the associated
  /// field name in the table class. It's explicit if `.named()` was called in
  /// the column builder.
  bool get implicit;

  String get name;

  ColumnName._();

  factory ColumnName([updates(ColumnNameBuilder b)]) = _$ColumnName;

  factory ColumnName.implicitly(String name) => ColumnName((b) => b
    ..implicit = true
    ..name = name);

  factory ColumnName.explicitly(String name) => ColumnName((b) => b
    ..implicit = false
    ..name = name);
}

const Map<ColumnType, String> dartTypeNames = {
  ColumnType.boolean: 'bool',
  ColumnType.text: 'String',
  ColumnType.integer: 'int',
  ColumnType.datetime: 'DateTime',
  ColumnType.blob: 'Uint8List',
  ColumnType.real: 'double',
};

/// Maps to the method name of a "QueryRow" from moor to extract a column type
/// of a result row.
const Map<ColumnType, String> readFromMethods = {
  ColumnType.boolean: 'readBool',
  ColumnType.text: 'readString',
  ColumnType.integer: 'readInt',
  ColumnType.datetime: 'readDateTime',
  ColumnType.blob: 'readBlob',
  ColumnType.real: 'readDouble',
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

/// A column, as specified by a getter in a table.
class SpecifiedColumn {
  /// The getter name of this column in the table class. It will also be used
  /// as getter name in the TableInfo class (as it needs to override the field)
  /// and in the generated data class that will be generated for each table.
  final String dartGetterName;

  /// The sql type of this column
  final ColumnType type;

  /// The name of this column, as chosen by the user
  final ColumnName name;

  /// An (optional) name to use as a json key instead of the [dartGetterName].
  final String overriddenJsonName;
  String get jsonKey => overriddenJsonName ?? dartGetterName;

  /// Whether the user has explicitly declared this column to be nullable, the
  /// default is false
  final bool nullable;

  /// Whether this column has auto increment.
  bool get hasAI => features.any((f) => f is AutoIncrement);

  final List<ColumnFeature> features;

  /// If this columns has custom constraints that should be used instead of the
  /// default ones.
  final String customConstraints;

  /// Dart code that generates the default expression for this column, or null
  /// if there is no default expression.
  final String defaultArgument;

  /// The [UsedTypeConverter], if one has been set on this column.
  final UsedTypeConverter typeConverter;

  /// The dart type that matches the values of this column. For instance, if a
  /// table has declared an `IntColumn`, the matching dart type name would be [int].
  String get dartTypeName {
    if (typeConverter != null) {
      return typeConverter.mappedType?.displayName;
    }
    return variableTypeName;
  }

  /// the Dart type of this column that can be handled by moors type mapping.
  /// Basically the same as [dartTypeName], minus custom types.
  String get variableTypeName => dartTypeNames[type];

  /// The column type from the dsl library. For instance, if a table has
  /// declared an `IntColumn`, the matching dsl column name would also be an
  /// `IntColumn`.
  String get dslColumnTypeName => const {
        ColumnType.boolean: 'BoolColumn',
        ColumnType.text: 'TextColumn',
        ColumnType.integer: 'IntColumn',
        ColumnType.datetime: 'DateTimeColumn',
        ColumnType.blob: 'BlobColumn',
        ColumnType.real: 'RealColumn',
      }[type];

  /// The `GeneratedColumn` class that implements the [dslColumnTypeName].
  /// For instance, if a table has declared an `IntColumn`, the matching
  /// implementation name would be an `GeneratedIntColumn`.
  String get implColumnTypeName => const {
        ColumnType.boolean: 'GeneratedBoolColumn',
        ColumnType.text: 'GeneratedTextColumn',
        ColumnType.integer: 'GeneratedIntColumn',
        ColumnType.datetime: 'GeneratedDateTimeColumn',
        ColumnType.blob: 'GeneratedBlobColumn',
        ColumnType.real: 'GeneratedRealColumn',
      }[type];

  /// Whether this column is required for insert statements, meaning that a
  /// non-absent value must be provided for an insert statement to be valid.
  bool get requiredDuringInsert {
    final aliasForPk = type == ColumnType.integer &&
        features.any((f) => f is PrimaryKey || f is AutoIncrement);
    return !nullable && defaultArgument == null && !aliasForPk;
  }

  /// The class inside the moor library that represents the same sql type as
  /// this column.
  String get sqlTypeName => sqlTypes[type];

  const SpecifiedColumn({
    this.type,
    this.dartGetterName,
    this.name,
    this.overriddenJsonName,
    this.customConstraints,
    this.nullable = false,
    this.features = const [],
    this.defaultArgument,
    this.typeConverter,
  });
}

abstract class ColumnFeature {
  const ColumnFeature();
}

/// A `PRIMARY KEY` column constraint.
class PrimaryKey extends ColumnFeature {
  const PrimaryKey();
}

class AutoIncrement extends ColumnFeature {
  static const AutoIncrement _instance = AutoIncrement._();

  const AutoIncrement._();

  factory AutoIncrement() => _instance;

  @override
  bool operator ==(other) => other is AutoIncrement;

  @override
  int get hashCode => 1337420;
}

abstract class LimitingTextLength extends ColumnFeature
    implements Built<LimitingTextLength, LimitingTextLengthBuilder> {
  @nullable
  int get minLength;

  @nullable
  int get maxLength;

  LimitingTextLength._();

  factory LimitingTextLength(void updates(LimitingTextLengthBuilder b)) =
      _$LimitingTextLength;

  factory LimitingTextLength.withLength({int min, int max}) =>
      LimitingTextLength((b) => b
        ..minLength = min
        ..maxLength = max);
}

class Reference extends ColumnFeature {
  final SpecifiedColumn referencedColumn;

  const Reference(this.referencedColumn);
}
