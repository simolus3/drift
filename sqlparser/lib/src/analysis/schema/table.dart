part of '../analysis.dart';

/// The aliases which can be used to refer to the rowid of a table. See
/// https://www.sqlite.org/lang_createtable.html#rowid
const aliasesForRowId = ['rowid', 'oid', '_rowid_'];

/// A database table. The information stored here will be used to resolve
/// references and for type inference.
class Table extends NamedResultSet with HasMetaMixin implements HumanReadable {
  /// The name of this table, as it appears in sql statements. This should be
  /// the raw name, not an escaped version.
  ///
  /// To obtain an escaped name, use [escapedName].
  @override
  final String name;

  @override
  final List<TableColumn> resolvedColumns;

  /// Filter the [resolvedColumns] for those that are
  /// [Column.includedInResults].
  List<TableColumn> get resultColumns =>
      resolvedColumns.where((c) => c.includedInResults).toList();

  /// Whether this table was created with an "WITHOUT ROWID" modifier
  final bool withoutRowId;

  /// Additional constraints set on this table.
  final List<TableConstraint> tableConstraints;

  /// The ast node that created this table
  final TableInducingStatement? definition;

  @override
  bool get visibleToChildren => true;

  TableColumn? _rowIdColumn;

  /// Constructs a table from the known [name] and [resolvedColumns].
  Table(
      {required this.name,
      required this.resolvedColumns,
      this.withoutRowId = false,
      this.tableConstraints = const [],
      this.definition}) {
    for (final column in resolvedColumns) {
      column.table = this;

      if (_rowIdColumn == null && column.isAliasForRowId()) {
        _rowIdColumn = column;
      }
    }
  }

  @override
  Column? findColumn(String name) {
    final defaultSearch = super.findColumn(name);
    if (defaultSearch != null) return defaultSearch;

    // handle aliases to rowids, see https://www.sqlite.org/lang_createtable.html#rowid
    if (aliasesForRowId.contains(name.toLowerCase()) && !withoutRowId) {
      return _rowIdColumn ?? RowId()
        ..table = this;
    }
    return null;
  }

  @override
  String humanReadableDescription() {
    return name;
  }
}

class TableAlias implements ResultSet, HumanReadable {
  final ResultSet delegate;
  final String alias;

  TableAlias(this.delegate, this.alias);

  @override
  List<Column> get resolvedColumns => delegate.resolvedColumns!;

  @override
  Column? findColumn(String name) => delegate.findColumn(name);

  @override
  ResultSet get resultSet => this;

  @override
  bool get visibleToChildren => delegate.visibleToChildren;

  @override
  String humanReadableDescription() {
    final delegateDescription = delegate is HumanReadable
        ? (delegate as HumanReadable).humanReadableDescription()
        : delegate.toString();

    return '$alias (alias to $delegateDescription)';
  }
}
