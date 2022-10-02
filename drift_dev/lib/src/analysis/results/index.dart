import 'element.dart';
import 'table.dart';

/// An index on a drift table.
///
/// Currently, indices can only be created through a `CREATE INDEX` statement in
/// a `.drift` file.
class DriftIndex extends DriftSchemaElement {
  /// The table on which this index is created.
  ///
  /// This may be null if the table couldn't be resolved.
  DriftTable? table;

  /// The `CREATE INDEX` SQL statement creating this index, as written down by
  /// the user.
  ///
  /// In generated code, another step will reforma this string to strip out
  /// comments and unncecessary whitespace.
  final String createStmt;

  DriftIndex(
    super.id,
    super.declaration, {
    required this.table,
    required this.createStmt,
  });

  @override
  String get dbGetterName => DriftSchemaElement.dbFieldName(id.name);

  @override
  Iterable<DriftElement> get references => [if (table != null) table!];
}
