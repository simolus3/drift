import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

part 'composer.dart';
part 'filter.dart';
part 'join.dart';
part 'ordering.dart';

/// Defines a class that holds the state for a [BaseTableManager]
class TableManagerState<
    DB extends GeneratedDatabase,
    T extends Table,
    DT extends DataClass,
    FS extends FilterComposer<DB, T>,
    OS extends OrderingComposer<DB, T>> {
  /// The database that the query will be executed on
  final DB db;

  /// The table that the query will be executed on
  final T table;

  /// The expression that will be applied to the query
  final Expression<bool>? filter;

  /// A set of [OrderingBuilder] which will be used to apply
  /// [OrderingTerm]s to the statement when it's eventually built
  final Set<OrderingBuilder> orderingBuilders;

  /// A set of [JoinBuilder] which will be used to create [Join]s
  /// that will be applied to the build statement
  final Set<JoinBuilder> joinBuilders;

  /// Whether the query should return distinct results
  final bool? distinct;

  /// If set, the maximum number of rows that will be returned
  final int? limit;

  /// If set, the number of rows that will be skipped
  final int? offset;

  /// The [FilterComposer] for this [TableManagerState]
  /// This class will be used to create filtering [Expression]s
  /// which will be applied to the statement when its eventually created
  final FS filteringComposer;

  /// The [OrderingComposer] for this [TableManagerState]
  /// This class will be used to create [OrderingTerm]s
  /// which will be applied to the statement when its eventually created
  final OS orderingComposer;

  /// Defines a class which holds the state for a table manager
  /// It contains the database instance, the table instance, and any filters/orderings that will be applied to the query
  /// This is held in a seperate class than the [BaseTableManager] so that the state can be passed down from the root manager to the lower level managers
  const TableManagerState({
    required this.db,
    required this.table,
    required this.filteringComposer,
    required this.orderingComposer,
    this.filter,
    this.distinct,
    this.limit,
    this.offset,
    this.orderingBuilders = const {},
    this.joinBuilders = const {},
  });

  /// Copy this state with the given values
  TableManagerState<DB, T, DT, FS, OS> copyWith({
    bool? distinct,
    int? limit,
    int? offset,
    Expression<bool>? filter,
    Set<OrderingBuilder>? orderingBuilders,
    Set<JoinBuilder>? joinBuilders,
  }) {
    return TableManagerState(
      db: db,
      table: table,
      filteringComposer: filteringComposer,
      orderingComposer: orderingComposer,
      filter: filter ?? this.filter,
      joinBuilders: joinBuilders ?? this.joinBuilders,
      orderingBuilders: orderingBuilders ?? this.orderingBuilders,
      distinct: distinct ?? this.distinct,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Helper for getting the table that's casted as a TableInfo
  /// This is needed due to dart's limitations with generics
  TableInfo<T, DT> get _tableAsTableInfo => table as TableInfo<T, DT>;

  /// Builds a joined  select statement, should be used when joins are present
  /// Will order, filter, and limit the statement using the state
  JoinedSelectStatement _buildJoinedSelectStatement() {
    // Build the joins
    final joins = joinBuilders.map((e) => e.buildJoin()).toList();

    // Create the joined statement
    final statement =
        db.select(_tableAsTableInfo, distinct: distinct ?? false).join(joins);

    // Apply the expression to the statement
    if (filter != null) {
      statement.where(filter!);
    }

    // Add orderings
    statement.orderBy(orderingBuilders.map((e) => e.buildTerm()).toList());

    // Set the limit and offset
    if (limit != null) {
      statement.limit(limit!, offset: offset);
    }
    return statement;
  }

  /// Builds a simple select statement, this should be used when there are no joins
  /// Will order, filter, and limit the statement using the state
  SimpleSelectStatement<T, DT> _buildSimpleSelectStatement() {
    // Create the statement
    final statement = db.select(_tableAsTableInfo, distinct: distinct ?? false);

    // Apply the expression to the statement
    if (filter != null) {
      statement.where((_) => filter!);
    }

    // Add orderings
    statement
        .orderBy(orderingBuilders.map((e) => (_) => e.buildTerm()).toList());

    // Set the limit and offset
    if (limit != null) {
      statement.limit(limit!, offset: offset);
    }
    return statement;
  }

  /// Build a select statement based on the manager state
  Selectable<DT> buildSelectStatement() {
    if (joinBuilders.isEmpty) {
      return _buildSimpleSelectStatement();
    } else {
      return _buildJoinedSelectStatement()
          .map((p0) => p0.readTable(_tableAsTableInfo));
    }
  }

  /// Build a delete statement based on the manager state
  // DeleteStatement buildDeleteStatement() {
  //   // Being that drift doesnt support joins on deletes, if there are any joins we will use 2 queries
  //   final DeleteStatement deleteStatement;
  //   // Check if there are any joins
  //   if (_joins.isEmpty) {
  //     // If there are no joins, we can just use a single delete statement
  //     deleteStatement = db.delete(_tableAsTableInfo);
  //     if (filter?.expression != null) {
  //       deleteStatement.where((_) => filter!.expression);
  //     }
  //   } else {
  //     // If there are joins, we need to use a subquery to get the rowIds
  //     final selectOnlyRowIdStatement =
  //         _buildJoinedStatement(onlyWithRowId: true);
  //     deleteStatement = db.delete(_tableAsTableInfo)
  //       ..where(
  //           (_) => _tableAsTableInfo.rowId.isInQuery(selectOnlyRowIdStatement));
  //   }
  //   return deleteStatement;
  // }
}

/// Defines the base class for a table manager
@internal
abstract class BaseTableManager<
    DB extends GeneratedDatabase,
    T extends TableInfo,
    DT extends DataClass,
    FS extends FilterComposer<DB, T>,
    OS extends OrderingComposer<DB, T>> {
  /// The state for this manager
  final TableManagerState<DB, T, DT, FS, OS> state;

  /// Create a new [BaseTableManager] instance
  const BaseTableManager(this.state);
}

/// Mixin that adds processed functions to a table manager
/// Is used to act on a table manager that has filtering/ordering applied
mixin ProcessedTableManagerMixin<
    DB extends GeneratedDatabase,
    T extends TableInfo,
    D extends DataClass,
    FS extends FilterComposer<DB, T>,
    OS extends OrderingComposer<DB, T>> on BaseTableManager<DB, T, D, FS, OS> {
  Future<D> getSingle() => state.buildSelectStatement().getSingle();
  Stream<D> watchSingle() => state.buildSelectStatement().watchSingle();
  Future<List<D>> get() => state.buildSelectStatement().get();
  Stream<List<D>> watch() => state.buildSelectStatement().watch();
  // Future<int> delete() => state.buildDeleteStatement().go();
}

/// A table manager that only has functions to return items based on the state build by parent managers
class ProcessedTableManager<
        DB extends GeneratedDatabase,
        T extends TableInfo,
        D extends DataClass,
        FS extends FilterComposer<DB, T>,
        OS extends OrderingComposer<DB, T>>
    extends BaseTableManager<DB, T, D, FS, OS>
    with ProcessedTableManagerMixin<DB, T, D, FS, OS> {
  /// A table manager that only has functions to return items based on the state build by parent managers
  ProcessedTableManager(super.state);
}

/// A table manager that has methods to filter the query
class TableManagerWithFiltering<
        DB extends GeneratedDatabase,
        T extends TableInfo,
        D extends DataClass,
        FS extends FilterComposer<DB, T>,
        OS extends OrderingComposer<DB, T>,
        C extends ProcessedTableManager<DB, T, D, FS, OS>>
    extends BaseTableManager<DB, T, D, FS, OS>
    with ProcessedTableManagerMixin<DB, T, D, FS, OS> {
  final C Function(TableManagerState<DB, T, D, FS, OS>) getChildManager;
  const TableManagerWithFiltering(super.state, {required this.getChildManager});
  C filter(ComposableFilter Function(FilterComposer f) f) {
    final filter = f(state.filteringComposer);
    return getChildManager(state.copyWith(
        filter: filter.expression,
        joinBuilders: state.joinBuilders.union(filter.joinBuilders)));
  }
}

/// A table manager that has methods to order the query
class TableManagerWithOrdering<
        DB extends GeneratedDatabase,
        T extends TableInfo,
        D extends DataClass,
        FS extends FilterComposer<DB, T>,
        OS extends OrderingComposer<DB, T>,
        C extends ProcessedTableManager<DB, T, D, FS, OS>>
    extends BaseTableManager<DB, T, D, FS, OS>
    with ProcessedTableManagerMixin<DB, T, D, FS, OS> {
  final C Function(TableManagerState<DB, T, D, FS, OS>) getChildManager;
  const TableManagerWithOrdering(super.state, {required this.getChildManager});
  C orderBy(ComposableOrdering Function(OrderingComposer o) o) {
    final orderings = o(state.orderingComposer);
    return getChildManager(state.copyWith(
        orderingBuilders: orderings.orderingBuilders,
        joinBuilders: state.joinBuilders.union(orderings.joinBuilders)));
  }
}

/// A table manager with top level function for creating, reading, updating, and deleting items
class RootTableManager<
        DB extends GeneratedDatabase,
        T extends TableInfo,
        D extends DataClass,
        FS extends FilterComposer<DB, T>,
        OS extends OrderingComposer<DB, T>,
        C extends ProcessedTableManager<DB, T, D, FS, OS>,
        CF extends TableManagerWithFiltering<DB, T, D, FS, OS, C>,
        CO extends TableManagerWithOrdering<DB, T, D, FS, OS, C>>
    extends BaseTableManager<DB, T, D, FS, OS>
    with ProcessedTableManagerMixin<DB, T, D, FS, OS> {
  final CF Function(TableManagerState<DB, T, D, FS, OS>)
      getChildManagerWithFiltering;
  final CO Function(TableManagerState<DB, T, D, FS, OS>)
      getChildManagerWithOrdering;

  const RootTableManager(super.state,
      {required this.getChildManagerWithFiltering,
      required this.getChildManagerWithOrdering});
  CF filter(ComposableFilter Function(FilterComposer f) f) {
    final filter = f(state.filteringComposer);
    return getChildManagerWithFiltering(state.copyWith(
        filter: filter.expression,
        joinBuilders: state.joinBuilders.union(filter.joinBuilders)));
  }

  CO orderBy(ComposableOrdering Function(OrderingComposer o) o) {
    final orderings = o(state.orderingComposer);
    return getChildManagerWithOrdering(state.copyWith(
        orderingBuilders: orderings.orderingBuilders,
        joinBuilders: state.joinBuilders.union(orderings.joinBuilders)));
  }
}
