// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'manager.dart';

/// Base class for all composers
///
/// Any class that can be composed using the `&` or `|` operator is called a composable.
/// [ComposableFilter] and [ComposableOrdering] are examples of composable classes.
///
/// The [Composer] class is a top level manager for this operation.
/// ```dart
/// filter((f) => f.id.equals(1) & f.name.equals('Bob'));
/// ```
/// `f` in this example is a [Composer] object, and `f.id.equals(1)` returns a [ComposableFilter] object.
///
/// The [Composer] class is responsible for creating joins between tables, and passing them down to the composable classes.
@internal
sealed class Composer<DB extends GeneratedDatabase, CT extends Table> {
  /// The database that the query will be executed on
  final DB $db;

  /// The table that the query will be executed on
  final CT $table;

  Composer(this.$db, this.$table);

  /// Utility for creating a composer which contains the joins needed to
  /// execute a query on a table that is referenced by a foreign key.
  B $composeWithJoins<RT extends Table, QC extends Composer<DB, RT>,
      B extends HasJoinBuilders>({
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
    final referencedComposer =
        getReferencedComposer($db, aliasedReferencedTable);

    // Run the user provided builder with the referencedQueryComposer
    // This may return a filter or ordering, but we only enforce that it's
    // a HasJoinBuilders
    final result = builder(referencedComposer);
    result.addJoinBuilders({joinBuilder});

    return result;
  }
}
