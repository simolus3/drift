import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

part 'composer.dart';
part 'filter.dart';
part 'join.dart';
part 'ordering.dart';

sealed class _StatementType<T extends Table, DT extends DataClass> {
  const _StatementType();
}

class _SimpleResult<T extends Table, DT extends DataClass>
    extends _StatementType<T, DT> {
  final SimpleSelectStatement<T, DT> statement;
  const _SimpleResult(this.statement);
}

class _JoinedResult<T extends Table, DT extends DataClass>
    extends _StatementType<T, DT> {
  final JoinedSelectStatement<T, DT> statement;

  const _JoinedResult(this.statement);
}

/// Defines a class that holds the state for a [BaseTableManager]
class TableManagerState<
    DB extends GeneratedDatabase,
    T extends Table,
    DT extends DataClass,
    FS extends FilterComposer<DB, T>,
    OS extends OrderingComposer<DB, T>> {
  /// The database that the query will be exeCCted on
  final DB db;

  /// The table that the query will be exeCCted on
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

  /// Builds a select statement with the given target columns, or all columns if none are provided
  _StatementType<T, DT> _buildSelectStatement(
      {Iterable<Column>? targetColumns,
      required bool addJoins,
      required bool applyFilters,
      required bool applyOrdering,
      required bool applyLimit}) {
    final joins = joinBuilders.map((e) => e.buildJoin()).toList();

    // If there are no joins and we are returning all columns, we can use a simple select statement
    if (targetColumns == null && !addJoins) {
      final simpleStatement =
          db.select(_tableAsTableInfo, distinct: distinct ?? false);
      // Apply the expression to the statement
      if (applyFilters && filter != null) {
        simpleStatement.where((_) => filter!);
      }
      // Add orderings
      if (applyOrdering) {
        simpleStatement.orderBy(
            orderingBuilders.map((e) => (_) => e.buildTerm()).toList());
      }
      // Set the limit and offset
      if (applyLimit && limit != null) {
        simpleStatement.limit(limit!, offset: offset);
      }
      return _SimpleResult(simpleStatement);
    } else {
      JoinedSelectStatement<T, DT> joinedStatement;
      // If we are only selecting specific columns, we can use a selectOnly statement
      if (targetColumns != null) {
        joinedStatement =
            (db.selectOnly(_tableAsTableInfo, distinct: distinct ?? false)
              ..addColumns(targetColumns));
        // Add the joins to the statement
        if (addJoins) {
          joinedStatement =
              joinedStatement.join(joins) as JoinedSelectStatement<T, DT>;
        }
      } else {
        joinedStatement = db
            .select(_tableAsTableInfo, distinct: distinct ?? false)
            .join(joins) as JoinedSelectStatement<T, DT>;
      }
      // Apply the expression to the statement
      if (applyFilters && filter != null) {
        joinedStatement.where(filter!);
      }
      // Add orderings
      if (applyOrdering) {
        joinedStatement
            .orderBy(orderingBuilders.map((e) => e.buildTerm()).toList());
      }
      // Set the limit and offset
      if (applyLimit && limit != null) {
        joinedStatement.limit(limit!, offset: offset);
      }
      return _JoinedResult(joinedStatement);
    }
  }

  /// Build a select statement based on the manager state
  Selectable<DT> buildSelectStatement(
      {Iterable<Column>? targetColumns,
      bool addJoins = true,
      bool applyFilters = true,
      bool applyOrdering = true,
      bool applyLimit = true}) {
    final result = _buildSelectStatement(
        targetColumns: targetColumns,
        addJoins: addJoins,
        applyFilters: applyFilters,
        applyOrdering: applyOrdering,
        applyLimit: applyLimit);
    return switch (result) {
      _SimpleResult() => result.statement,
      _JoinedResult() =>
        result.statement.map((p0) => p0.readTable(_tableAsTableInfo))
    };
  }

  // Build a delete statement based on the manager state
  DeleteStatement buildDeleteStatement() {
    // If there are any joins we will have to use a subquery to get the rowIds
    final DeleteStatement deleteStatement;
    if (joinBuilders.isEmpty) {
      deleteStatement = db.delete(_tableAsTableInfo);
      if (filter != null) {
        deleteStatement.where((_) => filter!);
      }
    } else {
      deleteStatement = db.delete(_tableAsTableInfo);
      for (var col in _tableAsTableInfo.primaryKey) {
        final subquery = _buildSelectStatement(
            targetColumns: [col],
            addJoins: true,
            applyFilters: true,
            applyOrdering: false,
            applyLimit: false) as _JoinedResult<T, DT>;
        deleteStatement.where((tbl) => col.isInQuery(subquery.statement));
      }
    }
    return deleteStatement;
  }
}

/// Base class for all table managers
/// Most of this classes functionality is kept in a seperate [TableManagerState] class
/// This is so that the state can be passed down to lower level managers
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
  Future<int> delete() => state.buildDeleteStatement().go();
}

/// Mixin for adding select functionality to a table manager
abstract class ProcessedTableManager<
        DB extends GeneratedDatabase,
        T extends TableInfo,
        D extends DataClass,
        FS extends FilterComposer<DB, T>,
        OS extends OrderingComposer<DB, T>>
    extends BaseTableManager<DB, T, D, FS, OS>
    implements
        MultiSelectable<D>,
        SingleSelectable<D>,
        SingleOrNullSelectable<D> {
  const ProcessedTableManager(super.state);
  @override
  Future<D> getSingle() => state.buildSelectStatement().getSingle();
  @override
  Stream<D> watchSingle() => state.buildSelectStatement().watchSingle();
  @override
  Future<List<D>> get() => state.buildSelectStatement().get();
  @override
  Stream<List<D>> watch() => state.buildSelectStatement().watch();
  @override
  Future<D?> getSingleOrNull() =>
      state.buildSelectStatement().getSingleOrNull();
  @override
  Stream<D?> watchSingleOrNull() =>
      state.buildSelectStatement().watchSingleOrNull();

  Future<int> delete() => state.buildDeleteStatement().go();
}

/// A table manager that has methods to filter the query
abstract class TableManagerWithFiltering<
        DB extends GeneratedDatabase,
        T extends TableInfo,
        D extends DataClass,
        FS extends FilterComposer<DB, T>,
        OS extends OrderingComposer<DB, T>,
        C extends ProcessedTableManager<DB, T, D, FS, OS>>
    extends ProcessedTableManager<DB, T, D, FS, OS> {
  final C Function(TableManagerState<DB, T, D, FS, OS>) _getChildManager;
  const TableManagerWithFiltering(super.state,
      {required C Function(TableManagerState<DB, T, D, FS, OS>)
          getChildManager})
      : _getChildManager = getChildManager;
  C filter(ComposableFilter Function(FS f) f) {
    final filter = f(state.filteringComposer);
    return _getChildManager(state.copyWith(
        filter: filter.expression,
        joinBuilders: state.joinBuilders.union(filter.joinBuilders)));
  }
}

/// A table manager that has methods to order the query
abstract class TableManagerWithOrdering<
        DB extends GeneratedDatabase,
        T extends TableInfo,
        D extends DataClass,
        FS extends FilterComposer<DB, T>,
        OS extends OrderingComposer<DB, T>,
        C extends ProcessedTableManager<DB, T, D, FS, OS>>
    extends ProcessedTableManager<DB, T, D, FS, OS> {
  final C Function(TableManagerState<DB, T, D, FS, OS>) _getChildManager;
  const TableManagerWithOrdering(super.state,
      {required C Function(TableManagerState<DB, T, D, FS, OS>)
          getChildManager})
      : _getChildManager = getChildManager;
  C orderBy(ComposableOrdering Function(OS o) o) {
    final orderings = o(state.orderingComposer);
    return _getChildManager(state.copyWith(
        orderingBuilders: orderings.orderingBuilders,
        joinBuilders: state.joinBuilders.union(orderings.joinBuilders)));
  }
}

/// A table manager with top level function for creating, reading, updating, and deleting items
abstract class RootTableManager<
    DB extends GeneratedDatabase,
    T extends TableInfo,
    D extends DataClass,
    FS extends FilterComposer<DB, T>,
    OS extends OrderingComposer<DB, T>,
    C extends ProcessedTableManager<DB, T, D, FS, OS>,
    CF extends TableManagerWithFiltering<DB, T, D, FS, OS, C>,
    CO extends TableManagerWithOrdering<DB, T, D, FS, OS, C>,
    CI extends Function> extends BaseTableManager<DB, T, D, FS, OS> {
  final CF Function(TableManagerState<DB, T, D, FS, OS>)
      _getChildManagerWithFiltering;
  final CO Function(TableManagerState<DB, T, D, FS, OS>)
      _getChildManagerWithOrdering;
  final CI _createInsertable;
  RootTableManager(super.state,
      {required CF Function(TableManagerState<DB, T, D, FS, OS>)
          getChildManagerWithFiltering,
      required CO Function(TableManagerState<DB, T, D, FS, OS>)
          getChildManagerWithOrdering,
      required CI createInsertable})
      : _getChildManagerWithFiltering = getChildManagerWithFiltering,
        _getChildManagerWithOrdering = getChildManagerWithOrdering,
        _createInsertable = createInsertable;
  CO filter(ComposableFilter Function(FS f) f) {
    final filter = f(state.filteringComposer);
    return _getChildManagerWithOrdering(state.copyWith(
        filter: filter.expression,
        joinBuilders: state.joinBuilders.union(filter.joinBuilders)));
  }

  CO all() {
    return _getChildManagerWithOrdering(state);
  }

  Future<int> create(
    Insertable<D> Function(CI o) f,
    {InsertMode? mode,
    UpsertClause<Table, dynamic>? onConflict},
  ) {
    return state.db
        .into(state.table)
        .insert(f(_createInsertable), mode: mode, onConflict: onConflict);
  }

  Future<D> createReturning(
    Insertable<D> Function(CI o) f,
    {InsertMode? mode,
    UpsertClause<Table, dynamic>? onConflict},
  ) {
    return state.db.into(state.table).insertReturning(f(_createInsertable),
        mode: mode, onConflict: onConflict) as Future<D>;
  }

  Future<void> bulkCreate(
    Iterable<Insertable<D>> Function(CI o) f,
    {InsertMode? mode,
    UpsertClause<Table, dynamic>? onConflict},
  ) {
    return state.db.batch((b) => b.insertAll(state.table, f(_createInsertable),
        mode: mode, onConflict: onConflict));
  }

  Future<bool> replace(Insertable<D> entry) {
    return state.db.update(state.table).replace(entry);
  }

  CF orderBy(ComposableOrdering Function(OS o) o) {
    final orderings = o(state.orderingComposer);
    return _getChildManagerWithFiltering(state.copyWith(
        orderingBuilders: orderings.orderingBuilders,
        joinBuilders: state.joinBuilders.union(orderings.joinBuilders)));
  }
}
