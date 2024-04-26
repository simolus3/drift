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

  /// If this composer was created by a referenced manager, this
  /// holds the JoinBuilder that will be used to join the referenced table
  /// to the current table
  late final JoinBuilder? $joinBuilder;

  Composer(this.$db, this.$table, {this.$joinBuilder});

  /// Create a [JoinBuilder] to connect this table to another table
  JoinBuilder $buildJoinForTable<C extends GeneratedColumn, RT extends Table,
          RC extends GeneratedColumn>(
      {required C Function(CT) getCurrentColumn,
      required RT referencedTable,
      required RC Function(RT) getReferencedColumn}) {
    final currentColumn = getCurrentColumn($table);
    final referencedColumn = getReferencedColumn(referencedTable);
    final aliasName =
        '${currentColumn.tableName}__${currentColumn.name}__${referencedColumn.tableName}__${referencedColumn.name}';
    final aliasedReferencedTable =
        $db.alias(referencedTable as TableInfo, aliasName);
    final aliasedReferencedColumn =
        getReferencedColumn(aliasedReferencedTable as RT);

    return JoinBuilder(
      currentTable: $table,
      currentColumn: currentColumn,
      referencedTable: aliasedReferencedTable,
      referencedColumn: aliasedReferencedColumn,
    );
  }

  /// This helper method will get the table that filters/orderings should be applied to
  /// If this composer has a join builder, this method will return the column from the aliased table
  /// Otherwise, it will return the column from the original table
  AC _columnWithAlias<AC extends GeneratedColumn>(AC column) {
    if ($joinBuilder != null) {
      return ($joinBuilder!.referencedTable as TableInfo)
          .columnsByName[column.$name] as AC;
    }
    return column;
  }
}
