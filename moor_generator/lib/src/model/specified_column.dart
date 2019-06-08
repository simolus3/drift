import 'package:analyzer/dart/ast/ast.dart';
import 'package:built_value/built_value.dart';

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

  /// Whether this column has been declared as the primary key via the
  /// column builder. The `primaryKey` field in the table class is unrelated to
  /// this.
  final bool declaredAsPrimaryKey;
  final List<ColumnFeature> features;

  /// If this columns has custom constraints that should be used instead of the
  /// default ones.
  final String customConstraints;

  /// If a default expression has been provided as the argument of
  /// ColumnBuilder.withDefault, contains the Dart code that references that
  /// expression.
  final Expression defaultArgument;

  /// The dart type that matches the values of this column. For instance, if a
  /// table has declared an `IntColumn`, the matching dart type name would be [int].
  String get dartTypeName => const {
        ColumnType.boolean: 'bool',
        ColumnType.text: 'String',
        ColumnType.integer: 'int',
        ColumnType.datetime: 'DateTime',
        ColumnType.blob: 'Uint8List',
        ColumnType.real: 'double',
      }[type];

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

  /// The class inside the moor library that represents the same sql type as
  /// this column.
  String get sqlTypeName => const {
        ColumnType.boolean: 'BoolType',
        ColumnType.text: 'StringType',
        ColumnType.integer: 'IntType',
        ColumnType.datetime: 'DateTimeType',
        ColumnType.blob: 'BlobType',
        ColumnType.real: 'RealType',
      }[type];

  const SpecifiedColumn({
    this.type,
    this.dartGetterName,
    this.name,
    this.overriddenJsonName,
    this.customConstraints,
    this.declaredAsPrimaryKey = false,
    this.nullable = false,
    this.features = const [],
    this.defaultArgument,
  });
}

abstract class ColumnFeature {
  const ColumnFeature();
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
