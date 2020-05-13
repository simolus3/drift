part of '../analysis.dart';

/// A database view. The information stored here will be used to resolve
/// references and for type inference.
class View with HasMetaMixin implements HumanReadable, ResolvesToResultSet {
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

  final List<ViewColumn> resolvedColumns;

  /// Filter the [resolvedColumns] for those that are
  /// [Column.includedInResults].
  List<ViewColumn> get resultColumns =>
      resolvedColumns.where((c) => c.includedInResults).toList();

  /// Whether this table was created with an "WITHOUT ROWID" modifier
  final bool withoutRowId;

  /// Additional constraints set on this table.
  final List<TableConstraint> tableConstraints;

  /// The ast node that created this table
  final TableInducingStatement definition;

  @override
  bool get visibleToChildren => true;

  ViewColumn _rowIdColumn;

  /// Constructs a table from the known [name] and [resolvedColumns].
  View(
      {@required this.name,
        this.resolvedColumns,
        this.withoutRowId = false,
        this.tableConstraints = const [],
        this.definition}) {
    for (final column in resolvedColumns) {
      column.view = this;

      if (_rowIdColumn == null && column.isAliasForRowId()) {
        _rowIdColumn = column;
      }
    }
  }

  @override
  Column findColumn(String name) {
//    final defaultSearch = super.findColumn(name);
//    if (defaultSearch != null) return defaultSearch;
//
//    // handle aliases to rowids, see https://www.sqlite.org/lang_createtable.html#rowid
//    if (aliasesForRowId.contains(name.toLowerCase()) && !withoutRowId) {
//      return _rowIdColumn ?? RowId()
//        ..table = this;
//    }
    return null;
  }

  @override
  String humanReadableDescription() {
    return name;
  }

  @override
  // TODO: implement resultSet
  ResultSet get resultSet => null;
}
//
//class TableAlias implements ResultSet, HumanReadable {
//  final ResultSet delegate;
//  final String alias;
//
//  TableAlias(this.delegate, this.alias);
//
//  @override
//  List<Column> get resolvedColumns => delegate.resolvedColumns;
//
//  @override
//  Column findColumn(String name) => delegate.findColumn(name);
//
//  @override
//  ResultSet get resultSet => this;
//
//  @override
//  bool get visibleToChildren => delegate.visibleToChildren;
//
//  @override
//  String humanReadableDescription() {
//    final delegateDescription = delegate is HumanReadable
//        ? (delegate as HumanReadable).humanReadableDescription()
//        : delegate.toString();
//
//    return '$alias (alias to $delegateDescription)';
//  }
//}
