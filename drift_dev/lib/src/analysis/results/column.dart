import 'package:analyzer/dart/element/type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sqlparser/sqlparser.dart' show GeneratedAs, ReferenceAction;
import 'package:sqlparser/utils/node_to_text.dart';

import '../../utils/string_escaper.dart';
import '../options.dart';
import 'dart.dart';
import 'element.dart';
import 'result_sets.dart';
import 'types.dart';

part '../../generated/analysis/results/column.g.dart';

class DriftColumn implements HasType {
  @override
  final ColumnType sqlType;

  @override
  bool get isArray => false;

  /// Whether this column represents the implicit `rowid` column added to tables
  /// by default.
  ///
  /// In sqlite, every table that wasn't create with `WITHOUT ROWID` has a rowid,
  /// an integer column uniquely identifying that row.
  /// When a table has a single primary key of an integer column, that column
  /// takes over the role of the rowid. In that case, drift will not expose an
  /// implicit `rowid` column on the table.
  final bool isImplicitRowId;

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
  @JsonKey(includeFromJson: false, includeToJson: false)
  late DriftElementWithResultSet owner;

  DriftColumn({
    required this.sqlType,
    required this.nullable,
    required this.nameInSql,
    required this.nameInDart,
    required this.declaration,
    this.isImplicitRowId = false,
    this.typeConverter,
    this.clientDefaultCode,
    this.defaultArgument,
    this.overriddenJsonName,
    this.documentationComment,
    this.constraints = const [],
    this.customConstraints,
    bool foreignConverter = false,
  }) {
    if (typeConverter != null && !foreignConverter) {
      typeConverter!.owningColumn = this;
    }
  }

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

class CustomColumnType {
  /// The Dart expression creating an instance of the `CustomSqlType` responsible
  /// for the column.
  final AnnotatedDartCode expression;
  final DartType dartType;

  CustomColumnType(this.expression, this.dartType);
}

class AppliedTypeConverter {
  /// The Dart expression creating an instance of the applied type converter.
  final AnnotatedDartCode expression;

  final DartType dartType;

  /// The JSON type representation of this column, if this type converter
  /// applies to the JSON serialization as well.
  final DartType? jsonType;
  final ColumnType sqlType;

  late DriftColumn? owningColumn;

  /// Whether the Dart-value output of this type converter is nullable.
  ///
  /// In other words, [dartType] is potentially nullable.
  final bool dartTypeIsNullable;

  /// Whether the SQL-value output of this type converter is nullable.
  ///
  /// In other words, [sqlType] is potentially nullable.
  final bool sqlTypeIsNullable;

  /// Whether this converter is one of the enum type converters built into
  /// drift.
  final bool isDriftEnumTypeConverter;

  /// Whether this type converter should also be used in the generated JSON
  /// serialization.
  bool get alsoAppliesToJsonConversion => jsonType != null;

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

  /// Type converters are stored as static fields in the table that created
  /// them. This will be the field name for this converter.
  String get fieldName => '\$converter${owningColumn!.nameInDart}';

  /// If this converter [canBeSkippedForNulls] and is applied to a nullable
  /// column, drift generates a new wrapped type converter which will deal with
  /// `null` values.
  /// That converter is stored in this field.
  String get nullableFieldName => '${fieldName}n';

  AppliedTypeConverter({
    required this.expression,
    required this.dartType,
    required this.sqlType,
    required this.dartTypeIsNullable,
    required this.sqlTypeIsNullable,
    required this.jsonType,
    required this.isDriftEnumTypeConverter,
  });
}

abstract class DriftColumnConstraint {
  const DriftColumnConstraint();
}

class UniqueColumn extends DriftColumnConstraint {
  const UniqueColumn();
}

@JsonSerializable()
class PrimaryKeyColumn extends DriftColumnConstraint {
  final bool isAutoIncrement;

  PrimaryKeyColumn(this.isAutoIncrement);

  factory PrimaryKeyColumn.fromJson(Map json) =>
      _$PrimaryKeyColumnFromJson(json);

  Map<String, Object?> toJson() => _$PrimaryKeyColumnToJson(this);
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

@JsonSerializable()
class ColumnGeneratedAs extends DriftColumnConstraint {
  final AnnotatedDartCode dartExpression;
  final bool stored;

  ColumnGeneratedAs(this.dartExpression, this.stored);

  factory ColumnGeneratedAs.fromJson(Map json) =>
      _$ColumnGeneratedAsFromJson(json);

  factory ColumnGeneratedAs.fromParser(GeneratedAs constraint) {
    return ColumnGeneratedAs(
        AnnotatedDartCode.build((b) => b
          ..addText('const ')
          ..addSymbol('CustomExpression', AnnotatedDartCode.drift)
          ..addText('(')
          ..addText(asDartLiteral(constraint.expression.toSql()))
          ..addText(')')),
        constraint.stored);
  }

  Map<String, Object?> toJson() => _$ColumnGeneratedAsToJson(this);
}

/// A column with a `CHECK()` generated from a Dart expression.
@JsonSerializable()
class DartCheckExpression extends DriftColumnConstraint {
  final AnnotatedDartCode dartExpression;

  DartCheckExpression(this.dartExpression);

  factory DartCheckExpression.fromJson(Map json) =>
      _$DartCheckExpressionFromJson(json);

  Map<String, Object?> toJson() => _$DartCheckExpressionToJson(this);
}

@JsonSerializable()
class LimitingTextLength extends DriftColumnConstraint {
  final int? minLength;

  final int? maxLength;

  LimitingTextLength({this.minLength, this.maxLength});

  factory LimitingTextLength.fromJson(Map json) =>
      _$LimitingTextLengthFromJson(json);

  Map<String, Object?> toJson() => _$LimitingTextLengthToJson(this);

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

class DefaultConstraintsFromSchemaFile extends DriftColumnConstraint {
  final String constraints;

  DefaultConstraintsFromSchemaFile(this.constraints);
}
