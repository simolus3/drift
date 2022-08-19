import 'package:drift/drift.dart' show DriftSqlType;

import 'dart.dart';
import 'element.dart';

class DriftColumn {
  final DriftSqlType sqlType;

  /// Whether the user has explicitly declared this column to be nullable.
  ///
  /// For Dart-defined columns, this defaults to `false`. For columns defined in
  /// a drift file, this value will be `true` if there is no `NOT NULL`
  /// constraint present on the column's definition.
  final bool nullable;

  final String nameInSql;
  final String nameInDart;

  final AppliedTypeConverter? typeConverter;

  final DriftDeclaration? declaration;

  DriftColumn({
    required this.sqlType,
    required this.nullable,
    required this.nameInSql,
    required this.nameInDart,
    this.typeConverter,
    this.declaration,
  });
}

class AppliedTypeConverter {
  /// The Dart expression creating an instance of the applied type converter.
  final AnnotatedDartCode expression;

  final AnnotatedDartCode dartType;
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

  AppliedTypeConverter({
    required this.expression,
    required this.dartType,
    required this.sqlType,
    required this.dartTypeIsNullable,
    required this.sqlTypeIsNullable,
    this.alsoAppliesToJsonConversion = false,
  });
}
