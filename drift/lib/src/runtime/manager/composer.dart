part of 'manager.dart';

/// A base class for writing annotations/filters/orderings which have the correct aliases & joins applied
@immutable
class Composer<Database extends GeneratedDatabase, CurrentTable extends Table> {
  /// The database instance used by the composer.
  final Database $db;

  /// This current table being managed by the composer without any aliases applies.
  /// Use [_aliasedTable] to get the table with alias.
  final CurrentTable $table;

  /// The [JoinBuilder] used by the composer.
  /// If this composer wasn't created by a join, this will be null.
  final JoinBuilder? $joinBuilder;

  /// The table being managed by the composer.
  /// If the composer was created by a join, this will be the aliased table.
  CurrentTable get _aliasedTable {
    return $joinBuilder?.referencedTable as CurrentTable? ?? $table;
  }

  /// If this composer is a root composer, this will contain all
  /// the joinBuilders which any children may have created
  final List<JoinBuilder> $joinBuilders = [];

  /// A function to add a join builder to the root composer
  ///
  /// If this composer is a root composer, this function will be used to add join builders
  /// to itself, otherwise it will be used to add join builders to the root composer.
  /// When a root composer creates a child composer, it will pass this function to the child composer
  /// so that the child composer can add join builders to the root composer.
  late final void Function(JoinBuilder) $addJoinBuilderToRootComposer;

  /// A function to remove a join builder from the root composer
  /// This is used to remove join builders that are no longer needed.
  /// e.g.
  /// ```
  /// db.managers.todos.filter((f) => f.category.id(5))
  /// ```
  /// When `f.category` is called, the join builder for the category table is created and added to `f` (the root composer).
  /// However, when `.id(5)` is called, we realize that we don't want to filter on `category.id`, but on `todos.category`.
  /// The filter is rewritten to filter on `todos.category` instead of `category.id` and the join builder is removed.
  ///
  /// This function only removes a single join builder. This is because the join builder may have been used by other composers.
  /// ```
  /// db.managers.todos.filter((f) => f.category.name('Math') & f.category.id(5))
  /// ```
  /// In this case we don't want `.id(5)` to remove all the join builders, because it is still needed by the `.name('Math')` filter.
  /// Therefore, we remove a single join builder.
  ///
  /// Don't worry, when we eventualy build the the query, the duplicate join builders will be removed.
  late final void Function(JoinBuilder) $removeJoinBuilderFromRootComposer;

  /// A helper method for creating composables that need
  /// the correct aliases for the column and the join builders.
  /// Every filter and ordering compasable is created using this method.
  ///
  /// Explaination:
  /// ```dart
  /// db.managers.categories.filter((f) => f.todos((todoFilterComposer) => todoFilterComposer.title.equals("Math Homework")))
  /// ```
  /// In the above example, `todoFilterComposer.title.equals("Math Homework")` creates a filter for the joined `todos` table.
  /// However this `todoFilterComposer` class needs to create the filter using the alias name of the table,
  /// This [$composableBuilder] function utility helps us create it correctly
  ///
  /// This function removes also joins when the arent needed
  /// See [$removeJoinBuilderFromRootComposer] for more information
  T $composableBuilder<T, C extends GeneratedColumn>(
      {required C column, required T Function(C column) builder}) {
    // The proper join builders and column for the builder
    final C columnForBuilder;

    // Get a copy of the column with the correct alias
    final aliasedColumn = _aliasedColumn(column);

    // If the column that the action is being performed on
    // is part of the actual join, then this join is not needed.
    // The action will then be performed on the original column.
    if ($joinBuilder?.referencedColumn == aliasedColumn &&
        $joinBuilder?.currentColumn is C) {
      columnForBuilder = $joinBuilder?.currentColumn as C;
      $removeJoinBuilderFromRootComposer($joinBuilder!);
    } else {
      columnForBuilder = aliasedColumn;
    }

    return builder(columnForBuilder);
  }

  /// A helper method for creating related composers.
  ///
  /// For example, a filter for a categories table.
  /// There is a filter on it for filtering todos.
  /// ```dart
  /// db.managers.categories.filter((f) => f.todos((todoFilterComposer) => todoFilterComposer.title.equals("Math Homework")))
  /// ```
  /// When we filter the todos, we will be creating a todos filter composer.
  /// This function is used to build that composer.
  /// It will create he needed joins and ensure that the correct table alias name is used internaly
  T $composerBuilder<T, CurrentColumn extends GeneratedColumn,
          RelatedTable extends Table, RelatedColumn extends GeneratedColumn>(
      {required Composer composer,
      required CurrentColumn Function(CurrentTable) getCurrentColumn,
      required RelatedTable referencedTable,
      required RelatedColumn Function(RelatedTable) getReferencedColumn,
      required T Function(JoinBuilder joinBuilder,
              {void Function(JoinBuilder)? $addJoinBuilderToRootComposer,
              void Function(JoinBuilder)? $removeJoinBuilderFromRootComposer})
          builder}) {
    // Get the column of this table which will be used to build the join
    final aliasedColumn = getCurrentColumn(_aliasedTable);

    // Use the provided callbacks to create a join builder
    final referencedColumn = getReferencedColumn(referencedTable);
    final aliasName = $_aliasNameGenerator(aliasedColumn, referencedColumn);
    final aliasedReferencedTable =
        $db.alias(referencedTable as TableInfo, aliasName);
    final aliasedReferencedColumn =
        getReferencedColumn(aliasedReferencedTable as RelatedTable);
    final referencedJoinBuilder = JoinBuilder(
        currentTable: _aliasedTable,
        currentColumn: aliasedColumn,
        referencedTable: aliasedReferencedTable,
        referencedColumn: aliasedReferencedColumn);
    $addJoinBuilderToRootComposer(referencedJoinBuilder);
    return builder(referencedJoinBuilder,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer);
  }

  /// A helper method for getting a aliased copy of a column.
  /// If the composer is part of a join, this will return the original column
  AliasedColumn _aliasedColumn<AliasedColumn extends GeneratedColumn>(
      AliasedColumn column) {
    return (_aliasedTable as TableInfo).columnsByName[column.name]
        as AliasedColumn;
  }

  /// Base class for all composers
  ///
  /// A composer can create child composers which can create more child composers.
  /// When a child composer is created, a join builder is created and added to the root composer.
  ///
  /// When the composer is finished, the [$joinBuilders] list will contain all the join builders that are needed to create the query.
  Composer({
    required this.$db,
    required this.$table,
    required JoinBuilder? joinBuilder,
    void Function(JoinBuilder)? $addJoinBuilderToRootComposer,
    void Function(JoinBuilder)? $removeJoinBuilderFromRootComposer,
  }) : $joinBuilder = joinBuilder {
    this.$addJoinBuilderToRootComposer = $addJoinBuilderToRootComposer ??
        ((JoinBuilder joinBuilder) => $joinBuilders.add(joinBuilder));
    this.$removeJoinBuilderFromRootComposer =
        $removeJoinBuilderFromRootComposer ??
            ((JoinBuilder joinBuilder) => $joinBuilders.remove(joinBuilder));
  }

  /// A helper method for creating a new composer from an existing composer
  Composer.fromComposer(Composer<Database, CurrentTable> composer)
      : this(
          $db: composer.$db,
          $table: composer.$table,
          joinBuilder: composer.$joinBuilder,
          $addJoinBuilderToRootComposer: composer.$addJoinBuilderToRootComposer,
          $removeJoinBuilderFromRootComposer:
              composer.$removeJoinBuilderFromRootComposer,
        );
}
