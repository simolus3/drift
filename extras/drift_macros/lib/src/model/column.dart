import 'package:drift/drift.dart';
import 'package:macros/macros.dart';

/// The underlying SQL type of a column analyzed by drift.
///
/// We distinguish between types directly supported by drift, and types that
/// are supplied by another library. Custom types can hold different Dart types,
/// but are a feature distinct from type converters: They indicate that a type
/// is directly supported by the underlying database driver, whereas a type
/// converter is a mapping done in drift.
///
/// In addition to the SQL type, we also track whether a column is nullable,
/// appears where an array is expected or has a type converter applied to it.
/// [HasType] is the interface for sql-typed elements and is implemented by
/// columns.
sealed class ColumnType {
  /// The builtin drift type used by this column.
  ///
  /// Even though it's unused there, custom types also have this field set -
  /// to [DriftSqlType.any] because drift doesn't reinterpret these values at
  /// all.
  final DriftSqlType builtin;

  const ColumnType._(this.builtin);

  const factory ColumnType.drift(DriftSqlType builtin) = ColumnDriftType;
}

final class ColumnDriftType extends ColumnType {
  const ColumnDriftType(super.builtin) : super._();
}

final class ColumnCustomType extends ColumnType {
  /// The Dart expression creating the custom type responsible for this column.
  final ExpressionCode expression;

  /// The Dart type of the custom type implementation.
  final TypeAnnotation dartType;

  const ColumnCustomType(this.expression, this.dartType)
      : super._(DriftSqlType.any);
}

final class ResolvedColumn {
  final ColumnType sqlType;

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
  final bool nullable;

  /// The (unescaped) name of this column in the database schema.
  final String nameInSql;

  /// The getter name of this column in the table class. It will also be used
  /// as getter name in the TableInfo class (as it needs to override the field)
  /// and in the generated data class that will be generated for each table.
  final String nameInDart;

  ResolvedColumn({
    required this.sqlType,
    required this.nullable,
    required this.nameInSql,
    required this.nameInDart,
    this.isImplicitRowId = false,
  });
}
