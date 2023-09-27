import 'package:sqlparser/sqlparser.dart';

import 'results.dart';

/// An index on a drift table.
///
/// Currently, indices can only be created through a `CREATE INDEX` statement in
/// a `.drift` file.
class DriftIndex extends DriftSchemaElement {
  /// The table on which this index is created.
  ///
  /// This may be null if the table couldn't be resolved.
  DriftTable? table;

  /// Columns of [table] that have been indexed.
  ///
  /// This list is empty for indices created in SQL because it can't represent
  /// all expressions being indexed. It is useful for Dart-defined indices to
  /// implement [createStatementForDartDefinition].
  List<DriftColumn> indexedColumns;

  /// Whethet the index has been declared to be unique.
  final bool unique;

  /// For indices created in drift files, the `CREATE INDEX` SQL statements as
  /// written by the user in the drift file.
  ///
  /// In generated code, another step will reformat this string to strip out
  /// comments and unncecessary whitespace.
  final String? createStmt;

  DriftIndex(
    super.id,
    super.declaration, {
    required this.table,
    required this.indexedColumns,
    required this.unique,
    required this.createStmt,
  });

  @override
  DriftElementKind get kind => DriftElementKind.dbIndex;

  @override
  String get dbGetterName => DriftSchemaElement.dbFieldName(id.name);

  @override
  Iterable<DriftElement> get references => [if (table != null) table!];

  /// The parsed `CREATE VIEW` statement from [createView].
  ///
  /// This node is not serialized and only set in the late-state, local file
  /// analysis.
  CreateIndexStatement? parsedStatement;

  /// At the moment, the index implementation in the generator writes the
  /// `CREATE INDEX` definition as a string into the generated code. This
  /// requires [parsedStatement] to be available when generating code. To ensure
  /// this for Dart-based index declarations, this method creates a suitable AST
  /// for a create index statement based on the information available in our
  /// element model.
  ///
  /// Note that Dart index definitions are less expressive than the ones in SQL,
  /// so this method should not be used for indices defined with SQL.
  void createStatementForDartDefinition() {
    parsedStatement = CreateIndexStatement(
      indexName: id.name,
      on: TableReference(table?.id.name ?? ''),
      unique: unique,
      columns: [
        for (final column in indexedColumns)
          IndexedColumn(Reference(columnName: column.nameInSql))
      ],
    );
  }
}

sealed class DriftIndexDefintion {}
