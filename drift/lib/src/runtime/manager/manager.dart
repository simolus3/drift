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
    OS extends OrderingComposer<DB, T>,
    C extends ProcessedTableManager<DB, T, DT, FS, OS, C, CI, CU>,
    CI extends Function,
    CU extends Function> {
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

  /// This function is used internaly to return a new instance of the child manager
  final C Function(TableManagerState<DB, T, DT, FS, OS, C, CI, CU>)
      _getChildManagerBuilder;

  /// This function is passed to the user to create a companion
  /// for inserting data into the table
  final CI _getInsertCompanionBuilder;

  /// This function is passed to the user to create a companion
  /// for updating data in the table
  final CU _getUpdateCompanionBuilder;

  /// Defines a class which holds the state for a table manager
  /// It contains the database instance, the table instance, and any filters/orderings that will be applied to the query
  /// This is held in a seperate class than the [BaseTableManager] so that the state can be passed down from the root manager to the lower level managers
  const TableManagerState({
    required this.db,
    required this.table,
    required this.filteringComposer,
    required this.orderingComposer,
    required C Function(TableManagerState<DB, T, DT, FS, OS, C, CI, CU>)
        getChildManagerBuilder,
    required CI getInsertCompanionBuilder,
    required CU getUpdateCompanionBuilder,
    this.filter,
    this.distinct,
    this.limit,
    this.offset,
    this.orderingBuilders = const {},
    this.joinBuilders = const {},
  })  : _getChildManagerBuilder = getChildManagerBuilder,
        _getInsertCompanionBuilder = getInsertCompanionBuilder,
        _getUpdateCompanionBuilder = getUpdateCompanionBuilder;

  /// Copy this state with the given values
  TableManagerState<DB, T, DT, FS, OS, C, CI, CU> copyWith({
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
      getChildManagerBuilder: _getChildManagerBuilder,
      getInsertCompanionBuilder: _getInsertCompanionBuilder,
      getUpdateCompanionBuilder: _getUpdateCompanionBuilder,
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
    T extends Table,
    DT extends DataClass,
    FS extends FilterComposer<DB, T>,
    OS extends OrderingComposer<DB, T>,
    C extends ProcessedTableManager<DB, T, DT, FS, OS, C, CI, CU>,
    CI extends Function,
    CU extends Function> {
  /// The state for this manager
  final TableManagerState<DB, T, DT, FS, OS, C, CI, CU> state;

  /// Create a new [BaseTableManager] instance
  const BaseTableManager(this.state);
  Future<int> delete() => state.buildDeleteStatement().go();

  C orderBy(ComposableOrdering Function(OS o) o) {
    final orderings = o(state.orderingComposer);
    return state._getChildManagerBuilder(state.copyWith(
        orderingBuilders:
            state.orderingBuilders.union(orderings.orderingBuilders),
        joinBuilders: state.joinBuilders.union(orderings.joinBuilders)));
  }

  C filter(ComposableFilter Function(FS f) f) {
    final filter = f(state.filteringComposer);
    return state._getChildManagerBuilder(state.copyWith(
        filter: state.filter == null
            ? filter.expression
            : filter.expression & state.filter!,
        joinBuilders: state.joinBuilders.union(filter.joinBuilders)));
  }
}

abstract class ProcessedTableManager<
        DB extends GeneratedDatabase,
        T extends Table,
        D extends DataClass,
        FS extends FilterComposer<DB, T>,
        OS extends OrderingComposer<DB, T>,
        C extends ProcessedTableManager<DB, T, D, FS, OS, C, CI, CU>,
        CI extends Function,
        CU extends Function>
    extends BaseTableManager<DB, T, D, FS, OS, C, CI, CU>
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

/// A table manager with top level function for creating, reading, updating, and deleting items
abstract class RootTableManager<
    DB extends GeneratedDatabase,
    T extends Table,
    D extends DataClass,
    FS extends FilterComposer<DB, T>,
    OS extends OrderingComposer<DB, T>,
    C extends ProcessedTableManager<DB, T, D, FS, OS, C, CI, CU>,
    CI extends Function,
    CU extends Function> extends BaseTableManager<DB, T, D, FS, OS, C, CI, CU> {
  const RootTableManager(super.state);

  C all() {
    return state._getChildManagerBuilder(state);
  }

  Future<int> create(Insertable<D> Function(CI o) f,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) {
    return state.db.into(state._tableAsTableInfo).insert(
        f(state._getInsertCompanionBuilder),
        mode: mode,
        onConflict: onConflict);
  }

  Future<D> createReturning(Insertable<D> Function(CI o) f,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) {
    return state.db.into(state._tableAsTableInfo).insertReturning(
        f(state._getInsertCompanionBuilder),
        mode: mode,
        onConflict: onConflict);
  }

  Future<void> bulkCreate(Iterable<Insertable<D>> Function(CI o) f,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) {
    return state.db.batch((b) => b.insertAll(
        state._tableAsTableInfo, f(state._getInsertCompanionBuilder),
        mode: mode, onConflict: onConflict));
  }

  Future<bool> replace(Insertable<D> entry) {
    return state.db.update(state._tableAsTableInfo).replace(entry);
  }
}
