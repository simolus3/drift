// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'manager.dart';

/// A class that holds the state for a query composer
@internal
class ComposerState<DB extends GeneratedDatabase, T extends Table>
    implements HasJoinBuilders {
  /// The database that the query will be executed on
  final DB db;

  /// The table that the query will be executed on
  final T table;

  @override
  final Set<JoinBuilder> joinBuilders;
  @override
  void addJoinBuilder(JoinBuilder builder) {
    joinBuilders.add(builder);
  }

  /// Get a random alias for a table
  String _getRandomAlias(TableInfo table) {
    var aliasName = '${table.actualTableName}__${Random().nextInt(4294967296)}';
    while (joinBuilders.aliasedNames.contains(aliasName)) {
      aliasName = '${table.actualTableName}__${Random().nextInt(4294967296)}';
      continue;
    }
    return aliasName;
  }

  /// Create a new query composer state
  ComposerState._(this.db, this.table, Set<JoinBuilder>? joinBuilders)
      : joinBuilders = joinBuilders ?? {};
}

@internal
class AliasedComposerBuilder<DB extends GeneratedDatabase, RT extends Table,
    CT extends Table> {
  ComposerState<DB, RT> state;
  CT aliasedTable;
  AliasedComposerBuilder(
    this.state,
    this.aliasedTable,
  );
}

/// Base class for all query composers
@internal
sealed class Composer<DB extends GeneratedDatabase, CT extends Table> {
  /// The state of the query composer
  final ComposerState<DB, CT> state;

  Composer.withAliasedTable(AliasedComposerBuilder<DB, dynamic, CT> data)
      : state = ComposerState._(
            data.state.db, data.aliasedTable, data.state.joinBuilders);
  Composer.empty(DB db, CT table) : state = ComposerState._(db, table, {});

  /// Helper method for creaing an aliased join
  /// and adding it to the state and Composable object

  B referenced<RT extends Table, QC extends Composer<DB, RT>,
      B extends HasJoinBuilders>({
    required GeneratedColumn Function(CT) getCurrentColumn,
    required RT referencedTable,
    required GeneratedColumn Function(RT) getReferencedColumn,
    required B Function(QC) builder,
    required QC Function(AliasedComposerBuilder<DB, CT, RT> data)
        getReferencedQueryComposer,
  }) {
    // Create an alias of the referenced table
    // We will never use `referencedTable` again, only the alias
    final aliasedReferencedTable = state.db.alias(referencedTable as TableInfo,
        state._getRandomAlias(referencedTable)) as RT;

    // We are a function to get the column of the current table,
    // This is so that if the `table` in `state` is an alias,
    // The user can't supply a column that does not have an alias
    // E.G. db.table.id instead of state.table.id
    final currentColumn = getCurrentColumn(state.table);

    // We are using a function to get the column of the referenced table
    // This is so that the user cant by mistake use a column of a table that is not aliased
    final referencedColumn = getReferencedColumn(aliasedReferencedTable);

    // Create a join builder for the referenced table
    final joinBuilder = JoinBuilder(
      currentTable: state.table,
      referencedTable: aliasedReferencedTable,
      currentColumn: currentColumn,
      referencedColumn: referencedColumn,
    );

    // Add the join builder to the state
    state.addJoinBuilder(joinBuilder);

    // Get the query composer for the referenced table, passing in the aliased
    // table and all the join builders
    final referencedQueryComposer = getReferencedQueryComposer(
        AliasedComposerBuilder(this.state, aliasedReferencedTable));

    // Run the user provided builder with the referencedQueryComposer
    // This may return a filter or ordering, but we only enforce that it's
    // a HasJoinBuilders
    final result = builder(referencedQueryComposer);

    // At this point it is possible that the result has created more joins
    // that state doesnt have, it is also possible that the result is missing
    // the `joinBuilder` we create above.
    // We will combine both sets and set it to `state.joinBuilders` and `result.joinBuilders`

    // Add the joins that may have been created in the filterBuilder to state
    for (var joinBuilder in result.joinBuilders.union(state.joinBuilders)) {
      state.addJoinBuilder(joinBuilder);
      result.addJoinBuilder(joinBuilder);
    }

    return result;
  }
}
