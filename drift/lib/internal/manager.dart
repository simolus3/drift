/// Internal library used by generated managers.
///
/// This library is not part of drift's public API and should not be imported
/// manually.
library drift.internal.manager;

import 'package:drift/drift.dart';
import 'package:drift/src/runtime/manager/manager.dart';

/// Utility for creating a composer which contains the joins needed to
/// execute a query on a table that is referenced by a foreign key.
B composeWithJoins<RT extends Table, DB extends GeneratedDatabase,
    CT extends Table, QC extends Composer<DB, RT>, B extends HasJoinBuilders>({
  required DB $db,
  required CT $table,
  required GeneratedColumn Function(CT) getCurrentColumn,
  required RT referencedTable,
  required GeneratedColumn Function(RT) getReferencedColumn,
  required B Function(QC) builder,
  required QC Function(DB db, RT table) getReferencedComposer,
}) {
  // The name of the alias will be created using the following logic:
  // "currentTableName__currentColumnName__referencedColumnName__referencedTableName"
  // This is to ensure that the alias is unique
  final currentColumn = getCurrentColumn($table);
  final tempReferencedColumn = getReferencedColumn(referencedTable);
  final aliasName =
      '${currentColumn.tableName}__${currentColumn.name}__${tempReferencedColumn.tableName}__${tempReferencedColumn.name}';
  final aliasedReferencedTable =
      $db.alias(referencedTable as TableInfo, aliasName);
  final aliasedReferencedColumn =
      getReferencedColumn(aliasedReferencedTable as RT);

  // Create a join builder for the referenced table
  final joinBuilder = JoinBuilder(
    currentTable: $table,
    currentColumn: currentColumn,
    referencedTable: aliasedReferencedTable,
    referencedColumn: aliasedReferencedColumn,
  );

  // Get the query composer for the referenced table, passing in the aliased
  // table and all the join builders
  final referencedComposer = getReferencedComposer($db, aliasedReferencedTable);

  // Run the user provided builder with the referencedQueryComposer
  // This may return a filter or ordering, but we only enforce that it's
  // a HasJoinBuilders
  final result = builder(referencedComposer);
  result.addJoinBuilders({joinBuilder});

  return result;
}
