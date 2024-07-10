// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'manager.dart';

class ComposerState<Database extends GeneratedDatabase,
    CurrentTable extends Table> {
  /// The database instance used by the composer.
  final Database db;

  /// This current table being managed by the composer without any aliases applies.
  /// Use [aliasedTable] to get the table with alias.
  final CurrentTable table;

  /// The [JoinBuilder] used by the composer.
  /// If this composer wasn't created by a join, this will be null.
  final JoinBuilder? joinBuilder;

  /// The list of parent composers.
  final List<Composer> parentComposers;

  /// The table being managed by the composer.
  /// If the composer was created by a join, this will be the aliased table.
  CurrentTable get aliasedTable {
    return joinBuilder?.referencedTable as CurrentTable? ?? table;
  }

  /// A class which holds the state of the composer.
  ///
  /// This class primary focus is creating joins between tables, and passing them down to the composable classes.
  ///
  /// {@macro manager_internal_use_only}
  ComposerState(this.db, this.table,
      [this.joinBuilder, this.parentComposers = const []]);

  /// Returns all the join builders from this composer and its parents.
  Set<JoinBuilder> allJoinBuilders() {
    return [
      ...parentComposers
          .map((e) => e.$state.allJoinBuilders())
          .expand((element) => element),
      joinBuilder,
    ].nonNulls.toSet();
  }

  /// A helper method for creating objects that need that require
  /// the correct alias for the column and the needed join builders.
  T composableBuilder<T, C extends GeneratedColumn>(
      {required C column,
      required T Function(C column, Set<JoinBuilder> joinBuilders) builder}) {
    // The proper join builders and column for the builder
    final C columnForBuilder;
    final Set<JoinBuilder> joinBuildersForBuilder;

    // Get a copy of the column with the correct alias
    final aliasedColumn = _aliasedColumn(column);

    // If the column that the action is being performed on
    // is part of the actual join, then this join is not needed.
    // The action will then be performed on the original column.
    if (joinBuilder?.referencedColumn == aliasedColumn &&
        joinBuilder?.currentColumn is C) {
      columnForBuilder = joinBuilder?.currentColumn as C;
      joinBuildersForBuilder = allJoinBuilders()..remove(joinBuilder);
    } else {
      columnForBuilder = aliasedColumn;
      joinBuildersForBuilder = allJoinBuilders();
    }

    return builder(columnForBuilder, joinBuildersForBuilder);
  }

  /// A helper method for creating related composers.
  T composerBuilder<T, CurrentColumn extends GeneratedColumn,
          RelatedTable extends Table, RelatedColumn extends GeneratedColumn>(
      {required Composer composer,
      required CurrentColumn Function(CurrentTable) getCurrentColumn,
      required RelatedTable referencedTable,
      required RelatedColumn Function(RelatedTable) getReferencedColumn,
      required T Function(
              JoinBuilder joinBuilder, List<Composer> parentComposers)
          builder}) {
    // Get the column of this table which will be used to build the join
    final aliasedColumn = getCurrentColumn(aliasedTable);

    // Use the provided callbacks to create a join builder
    final referencedColumn = getReferencedColumn(referencedTable);
    final aliasName = $_aliasNameGenerator(aliasedColumn, referencedColumn);
    final aliasedReferencedTable =
        db.alias(referencedTable as TableInfo, aliasName);
    final aliasedReferencedColumn =
        getReferencedColumn(aliasedReferencedTable as RelatedTable);
    final referencedJoinBuilder = JoinBuilder(
      currentTable: aliasedTable,
      currentColumn: aliasedColumn,
      referencedTable: aliasedReferencedTable,
      referencedColumn: aliasedReferencedColumn,
    );
    return builder(referencedJoinBuilder, [...parentComposers, composer]);
  }

  /// A helper method for getting a aliased copy of a column.
  /// If the composer is part of a join, this will return the original column
  AliasedColumn _aliasedColumn<AliasedColumn extends GeneratedColumn>(
      AliasedColumn column) {
    return (aliasedTable as TableInfo).columnsByName[column.name]
        as AliasedColumn;
  }
}

sealed class Composer<Database extends GeneratedDatabase,
    CurrentTable extends Table> {
  /// The class which holds the state of the composer.
  ///
  /// See [ComposerState] for more information
  final ComposerState<Database, CurrentTable> $state;

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
  Composer(this.$state);
}
