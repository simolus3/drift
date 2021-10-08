import 'package:drift_dev/src/analyzer/options.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:sqlparser/sqlparser.dart';

import 'model.dart';

/// An sql index.
///
/// Indices can only be declared in moor files at the moment.
class MoorIndex extends MoorSchemaEntity {
  /// The table on which this index is created.
  ///
  /// This field can be null in case the table wasn't resolved.
  MoorTable? table;
  final String name;

  /// The sql statement creating this index.
  final String createStmt;

  @override
  final IndexDeclaration declaration;

  MoorIndex(this.name, this.declaration, this.createStmt, [this.table]);

  factory MoorIndex.fromMoor(CreateIndexStatement stmt, FoundFile file) {
    return MoorIndex(
      stmt.indexName,
      MoorIndexDeclaration.fromNodeAndFile(stmt, file),
      stmt.span!.text,
    );
  }

  @override
  String get dbGetterName => dbFieldName(name);

  @override
  String get displayName => name;

  /// The `CREATE INDEX` statement creating this index.
  ///
  /// Unlike [createStmt], this can be formatted to exclude comments and
  /// unnecessary whitespace depending on the [options].
  String createSql(MoorOptions options) {
    return declaration.formatSqlIfAvailable(options) ?? createStmt;
  }

  @override
  Iterable<MoorSchemaEntity> get references {
    if (table == null) {
      return const Iterable.empty();
    }
    return [table!];
  }
}
