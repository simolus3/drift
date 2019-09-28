part of '../analysis.dart';

/// Something that will resolve to an [ResultSet] when referred to via
/// the [ReferenceScope].
abstract class ResolvesToResultSet with Referencable {
  ResultSet get resultSet;
}

/// Something that returns a set of columns when evaluated.
abstract class ResultSet implements ResolvesToResultSet {
  /// The columns that will be returned when evaluating this query.
  List<Column> get resolvedColumns;

  @override
  ResultSet get resultSet => this;

  Column findColumn(String name) {
    return resolvedColumns.firstWhere((c) => c.name == name,
        orElse: () => null);
  }
}

/// A database table. The information stored here will be used to resolve
/// references and for type inference.
class Table with ResultSet, VisibleToChildren, HasMetaMixin {
  /// The name of this table, as it appears in sql statements. This should be
  /// the raw name, not an escaped version.
  final String name;

  @override
  final List<TableColumn> resolvedColumns;

  /// Whether this table was created with an "WITHOUT ROWID" modifier
  final bool withoutRowId;

  /// Additional constraints set on this table.
  final List<TableConstraint> tableConstraints;

  /// The ast node that created this table
  final CreateTableStatement definition;

  /// Constructs a table from the known [name] and [resolvedColumns].
  Table(
      {@required this.name,
      this.resolvedColumns,
      this.withoutRowId = false,
      this.tableConstraints = const [],
      this.definition}) {
    for (var column in resolvedColumns) {
      column.table = this;
    }
  }
}
