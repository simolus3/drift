import 'package:analyzer/dart/element/type.dart';
import 'package:drift/drift.dart' show DriftSqlType;
import 'package:json_annotation/json_annotation.dart';
import 'package:sqlparser/sqlparser.dart' show ReferenceAction;

import '../../analyzer/options.dart';
import 'dart.dart';
import 'element.dart';
import 'types.dart';

class DriftColumn implements HasType {
  @override
  final DriftSqlType sqlType;

  @override
  bool get isArray => false;

  /// Whether the user has explicitly declared this column to be nullable.
  ///
  /// For Dart-defined columns, this defaults to `false`. For columns defined in
  /// a drift file, this value will be `true` if there is no `NOT NULL`
  /// constraint present on the column's definition.
  @override
  final bool nullable;

  /// The (unescaped) name of this column in the database schema.
  final String nameInSql;

  /// The getter name of this column in the table class. It will also be used
  /// as getter name in the TableInfo class (as it needs to override the field)
  /// and in the generated data class that will be generated for each table.
  final String nameInDart;

  /// The documentation comment associated with this column
  ///
  /// Stored as a multi line string with leading triple-slashes `///` for every
  /// line.
  final String? documentationComment;

  /// An (optional) name to use as a json key instead of the [nameInDart].
  final String? overriddenJsonName;

  /// Column constraints that should be applied to this column.
  final List<DriftColumnConstraint> constraints;

  /// If this columns has custom constraints that should be used instead of the
  /// default ones.
  final String? customConstraints;

  /// The Dart code generating the default expression for this column (as an
  /// `Expression` instance from `package:drift`).
  final AnnotatedDartCode? defaultArgument;

  /// Dart code for the `clientDefault` expression, or null if it hasn't been
  /// set.
  final AnnotatedDartCode? clientDefaultCode;

  @override
  final AppliedTypeConverter? typeConverter;

  final DriftDeclaration declaration;

  /// The table or view owning this column.
  @JsonKey(ignore: true)
  late DriftElement owner;

  DriftColumn({
    required this.sqlType,
    required this.nullable,
    required this.nameInSql,
    required this.nameInDart,
    required this.declaration,
    this.typeConverter,
    this.clientDefaultCode,
    this.defaultArgument,
    this.overriddenJsonName,
    this.documentationComment,
    this.constraints = const [],
    this.customConstraints,
  });

  /// Whether this column has a `GENERATED AS` column constraint.
  bool get isGenerated => constraints.any((e) => e is ColumnGeneratedAs);

  /// Whether this column was declared inside a `.drift` file.
  bool get declaredInDriftFile => declaration.isDriftDeclaration;

  /// The actual json key to use when serializing a data class of this table
  /// to json.
  ///
  /// This respectts the [overriddenJsonName], if any, as well as [options].
  String getJsonKey([DriftOptions options = const DriftOptions.defaults()]) {
    if (overriddenJsonName != null) return overriddenJsonName!;

    final useColumnName = options.useColumnNameAsJsonKeyWhenDefinedInMoorFile &&
        declaredInDriftFile;
    return useColumnName ? nameInSql : nameInDart;
  }

  bool hasEqualSqlName(String otherSqlName) =>
      nameInSql.toLowerCase() == otherSqlName.toLowerCase();

  @override
  String toString() {
    return 'Column $nameInSql in $owner';
  }
}

class AppliedTypeConverter {
  /// The Dart expression creating an instance of the applied type converter.
  final AnnotatedDartCode expression;

  final DartType dartType;
  final DriftSqlType sqlType;

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
  bool get canBeSkippedForNulls => !dartTypeIsNullable && !sqlTypeIsNullable;

  /// Whether this converter maps to a nullable Dart type, depending on
  /// whether the type in SQL is nullable.
  bool mapsToNullableDart(bool nullableInSql) {
    return dartTypeIsNullable || (canBeSkippedForNulls && nullableInSql);
  }

  AppliedTypeConverter({
    required this.expression,
    required this.dartType,
    required this.sqlType,
    required this.dartTypeIsNullable,
    required this.sqlTypeIsNullable,
    this.alsoAppliesToJsonConversion = false,
  });
}

abstract class DriftColumnConstraint {
  const DriftColumnConstraint();
}

class UniqueColumn extends DriftColumnConstraint {
  const UniqueColumn();
}

class PrimaryKeyColumn extends DriftColumnConstraint {
  final bool isAutoIncrement;

  PrimaryKeyColumn(this.isAutoIncrement);
}

class ForeignKeyReference extends DriftColumnConstraint {
  late final DriftColumn otherColumn;
  final ReferenceAction? onUpdate;
  final ReferenceAction? onDelete;

  ForeignKeyReference(this.otherColumn, this.onUpdate, this.onDelete);

  ForeignKeyReference.unresolved(this.onUpdate, this.onDelete);

  @override
  String toString() {
    return 'ForeignKeyReference(to $otherColumn, onUpdate = $onUpdate, '
        'onDelete = $onDelete)';
  }
}

class ColumnGeneratedAs extends DriftColumnConstraint {
  final AnnotatedDartCode dartExpression;
  final bool stored;

  ColumnGeneratedAs(this.dartExpression, this.stored);
}

/// A column with a `CHECK()` generated from a Dart expression.
class DartCheckExpression extends DriftColumnConstraint {
  final AnnotatedDartCode dartExpression;

  DartCheckExpression(this.dartExpression);
}

class LimitingTextLength extends DriftColumnConstraint {
  final int? minLength;

  final int? maxLength;

  LimitingTextLength({this.minLength, this.maxLength});

  @override
  int get hashCode => minLength.hashCode ^ maxLength.hashCode;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    final typedOther = other as LimitingTextLength;
    return typedOther.minLength == minLength &&
        typedOther.maxLength == maxLength;
  }
}
