part of '../analysis.dart';

/// A database view. The information stored here will be used to resolve
/// references and for type inference.
class View extends NamedResultSet with HasMetaMixin implements HumanReadable {
  @override
  final String name;

  @override
  final List<ColumnWithType> resolvedColumns;

  /// The ast node that created this view
  final CreateViewStatement? definition;

  @override
  bool get visibleToChildren => true;

  /// Constructs a view from the known [name] and [resolvedColumns].
  View({
    required this.name,
    required this.resolvedColumns,
    this.definition,
  }) {
    for (final column in resolvedColumns) {
      if (column is ViewColumn) column.view = this;
    }
  }

  @override
  String humanReadableDescription() {
    return name;
  }
}
