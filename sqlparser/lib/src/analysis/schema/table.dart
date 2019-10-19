part of '../analysis.dart';

/// The aliases which can be used to refer to the rowid of a table. See
/// https://www.sqlite.org/lang_createtable.html#rowid
const aliasesForRowId = ['rowid', 'oid', '_rowid_'];

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

  TableColumn _rowIdColumn;

  /// Constructs a table from the known [name] and [resolvedColumns].
  Table(
      {@required this.name,
      this.resolvedColumns,
      this.withoutRowId = false,
      this.tableConstraints = const [],
      this.definition}) {
    for (var column in resolvedColumns) {
      column.table = this;

      if (_rowIdColumn == null && column.isAliasForRowId()) {
        _rowIdColumn = column;
      }
    }
  }

  @override
  Column findColumn(String name) {
    final defaultSearch = super.findColumn(name);
    if (defaultSearch != null) return defaultSearch;

    // handle aliases to rowids, see https://www.sqlite.org/lang_createtable.html#rowid
    if (aliasesForRowId.contains(name.toLowerCase()) && !withoutRowId) {
      return _rowIdColumn ?? RowId();
    }
    return null;
  }
}
