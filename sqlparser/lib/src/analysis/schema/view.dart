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

  /// Constructs a view from the known [name] and [resolvedColumns].
  View({
    @required this.name,
    @required this.resolvedColumns,
    this.definition,
  }) {
    for (final column in resolvedColumns) {
      column.view = this;
    }
  }

  @override
  String humanReadableDescription() {
    return name;
  }
}
