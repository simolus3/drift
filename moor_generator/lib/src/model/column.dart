//@dart=2.9
import 'package:moor_generator/src/analyzer/options.dart';

import 'declarations/declaration.dart';
import 'types.dart';
import 'used_type_converter.dart';

/// The column types in sql.
enum ColumnType { integer, text, boolean, datetime, blob, real }

/// Name of a column. Contains additional info on whether the name was chosen
/// implicitly (based on the dart getter name) or explicitly (via an named())
/// call in the column builder dsl.
class ColumnName {
  /// A column name is implicit if it has been looked up with the associated
  /// field name in the table class. It's explicit if `.named()` was called in
  /// the column builder.
  final bool implicit;

  final String name;

  ColumnName.implicitly(this.name) : implicit = true;
  ColumnName.explicitly(this.name) : implicit = false;

  @override
  int get hashCode => name.hashCode + implicit.hashCode * 31;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    // ignore: test_types_in_equals
    final typedOther = other as ColumnName;
    return typedOther.implicit == implicit && typedOther.name == name;
  }

  @override
  String toString() {
    return 'ColumnName($name, implicit = $implicit)';
  }
}

/// A column, as specified by a getter in a table.
class MoorColumn implements HasDeclaration, HasType {
  /// The getter name of this column in the table class. It will also be used
  /// as getter name in the TableInfo class (as it needs to override the field)
  /// and in the generated data class that will be generated for each table.
  final String dartGetterName;

  /// The declaration of this column, contains information about where this
  /// column was created in source code.
  @override
  final ColumnDeclaration declaration;

  /// Whether this column was declared inside a moor file.
  bool get declaredInMoorFile => declaration?.isDefinedInMoorFile ?? false;

  /// The sql type of this column
  @override
  final ColumnType type;

  /// The name of this column, as chosen by the user
  final ColumnName name;

  /// An (optional) name to use as a json key instead of the [dartGetterName].
  final String overriddenJsonName;
  String getJsonKey([MoorOptions options = const MoorOptions.defaults()]) {
    if (overriddenJsonName != null) return overriddenJsonName;

    final useColumnName = options.useColumnNameAsJsonKeyWhenDefinedInMoorFile &&
        declaredInMoorFile;
    return useColumnName ? name.name : dartGetterName;
  }

  /// Whether the user has explicitly declared this column to be nullable, the
  /// default is false
  @override
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

  /// Dart code for the `clientDefault` expression, or null if it hasn't been
  /// set.
  final String clientDefaultCode;

  /// The [UsedTypeConverter], if one has been set on this column.
  @override
  final UsedTypeConverter typeConverter;

  /// The documentation comment associated with this column
  ///
  /// Stored as a multi line string with leading triple-slashes `///` for every line
  final String documentationComment;

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

  MoorColumn({
    this.type,
    this.dartGetterName,
    this.name,
    this.overriddenJsonName,
    this.customConstraints,
    this.nullable = false,
    this.features = const [],
    this.defaultArgument,
    this.clientDefaultCode,
    this.typeConverter,
    this.declaration,
    this.documentationComment,
  });
}

abstract class ColumnFeature {
  const ColumnFeature();
}

/// A `PRIMARY KEY` column constraint.
class PrimaryKey extends ColumnFeature {
  const PrimaryKey();
}

class AutoIncrement extends PrimaryKey {
  static const AutoIncrement _instance = AutoIncrement._();

  const AutoIncrement._();

  factory AutoIncrement() => _instance;

  @override
  bool operator ==(dynamic other) => other is AutoIncrement;

  @override
  int get hashCode => 1337420;
}

class LimitingTextLength extends ColumnFeature {
  final int minLength;

  final int maxLength;

  LimitingTextLength({this.minLength, this.maxLength});

  @override
  int get hashCode => minLength.hashCode ^ maxLength.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    // ignore: test_types_in_equals
    final typedOther = other as LimitingTextLength;
    return typedOther.minLength == minLength &&
        typedOther.maxLength == maxLength;
  }
}
