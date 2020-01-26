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

/// A custom result set that has columns but isn't a table.
class CustomResultSet with ResultSet {
  @override
  final List<Column> resolvedColumns;

  CustomResultSet(this.resolvedColumns);
}

/// A database table. The information stored here will be used to resolve
/// references and for type inference.
class Table
    with ResultSet, VisibleToChildren, HasMetaMixin
    implements HumanReadable {
  /// The name of this table, as it appears in sql statements. This should be
  /// the raw name, not an escaped version.
  ///
  /// To obtain an escaped name, use [escapedName].
  final String name;

  /// If [name] is a reserved sql keyword, wraps it in double ticks. Otherwise
  /// just returns the [name] directly.
  String get escapedName {
    return isKeywordLexeme(name) ? '"$name"' : name;
  }

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
  final TableInducingStatement definition;

  TableColumn _rowIdColumn;

  /// Constructs a table from the known [name] and [resolvedColumns].
  Table(
      {@required this.name,
      this.resolvedColumns,
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
  Column findColumn(String name) {
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
