part of '../analysis.dart';

/// A database view. The information stored here will be used to resolve
/// references and for type inference.
class View with HasMetaMixin, ResultSet implements HumanReadable {
  /// The name of this view, as it appears in sql statements. This should be
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
  final List<ViewColumn> resolvedColumns;

  /// The ast node that created this table
  final CreateViewStatement definition;

  @override
  bool get visibleToChildren => true;

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
}

List<ViewColumn> _createColumns(
    List<Column> resolvedColumns, List<String> columnNames) {
  final columns = List<ViewColumn>(resolvedColumns.length);
  for (var i = 0; i < resolvedColumns.length; ++i) {
    columns[i] = ViewColumn(resolvedColumns[i], columnNames?.elementAt(i));
  }
  return columns;
}
