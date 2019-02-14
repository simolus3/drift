import 'package:built_value/built_value.dart';
import 'package:sally_generator/src/sqlite_keywords.dart' show isSqliteKeyword;

part 'specified_column.g.dart';

enum ColumnType { integer, text, boolean, datetime }

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

  ColumnName escapeIfSqlKeyword() {
    if (isSqliteKeyword(name)) {
      return rebuild((b) => b.name = '`$name`'); // wrap name in backticks
    } else {
      return this;
    }
  }

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

  /// The dart type that matches this column. For instance, if a table has
  /// declared an `IntColumn`, the matching dart type name would be [int].
  String get dartTypeName => {
        ColumnType.boolean: 'bool',
        ColumnType.text: 'String',
        ColumnType.integer: 'int',
        ColumnType.datetime: 'DateTime',
      }[type];

  /// The column type from the dsl library. For instance, if a table has
  /// declared an `IntColumn`, the matching dsl column name would also be an
  /// `IntColumn`.
  String get dslColumnTypeName => {
        ColumnType.boolean: 'BoolColumn',
        ColumnType.text: 'TextColumn',
        ColumnType.integer: 'IntColumn',
        ColumnType.datetime: 'DateTimeColumn',
      }[type];

  /// The `GeneratedColumn` class that implements the [dslColumnTypeName].
  /// For instance, if a table has declared an `IntColumn`, the matching
  /// implementation name would be an `GeneratedIntColumn`.
  String get implColumnTypeName => {
        ColumnType.boolean: 'GeneratedBoolColumn',
        ColumnType.text: 'GeneratedTextColumn',
        ColumnType.integer: 'GeneratedIntColumn',
        ColumnType.datetime: 'GeneratedDateTimeColumn',
      }[type];

  /// The class inside the sally library that represents the same sql type as
  /// this column.
  String get sqlTypeName => {
        ColumnType.boolean: 'BoolType',
        ColumnType.text: 'StringType',
        ColumnType.integer: 'IntType',
        ColumnType.datetime: 'DateTimeType',
      }[type];

  const SpecifiedColumn(
      {this.type,
      this.dartGetterName,
      this.name,
      this.declaredAsPrimaryKey = false,
      this.nullable = false,
      this.features = const []});
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
