part of '../analysis.dart';

/// A database view. The information stored here will be used to resolve
/// references and for type inference.
class View extends NamedResultSet with HasMetaMixin implements HumanReadable {
  @override
  final String name;

  @override
  final List<ViewColumn> resolvedColumns;

  /// The ast node that created this table
  final CreateViewStatement definition;

  /// Constructs a view from the known [name] and [selectColumns].
  View({
    @required this.name,
    @required List<Column> selectColumns,
    List<String> columnNames,
    this.definition,
  })  : assert(
            columnNames == null || columnNames.length == selectColumns.length),
        resolvedColumns = _createColumns(selectColumns, columnNames) {
    for (final column in resolvedColumns) {
      column.view = this;
    }
  }

  @override
  String humanReadableDescription() {
    return name;
  }

  static List<ViewColumn> _createColumns(
      List<Column> resolvedColumns, List<String> columnNames) {
    final columns = List<ViewColumn>(resolvedColumns.length);
    for (var i = 0; i < resolvedColumns.length; ++i) {
      columns[i] = ViewColumn(resolvedColumns[i], columnNames?.elementAt(i));
    }
    return columns;
  }
}
