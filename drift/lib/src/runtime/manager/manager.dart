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
///
/// It holds the state for manager of [T] table in [DB] database, used to return [DT] data classes/rows.
/// It holds the [FS] Filters and [OS] Orderings for the manager.
///
/// It also holds the [CI] and [CU] functions that are used to create companion builders for inserting and updating data.
/// E.G Instead of `CategoriesCompanion.insert(name: "School")` you would use `(f) => f(name: "School")`
///
/// The [C] generic refers to the type of the child manager that will be created when a filter/ordering is applied
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
      {Iterable<Expression>? targetColumns}) {
    final joins = joinBuilders.map((e) => e.buildJoin()).toList();

    // If there are no joins and we are returning all columns, we can use a simple select statement
    if (joins.isEmpty && targetColumns == null) {
      final simpleStatement =
          db.select(_tableAsTableInfo, distinct: distinct ?? false);
      // Apply the expression to the statement
      if (filter != null) {
        simpleStatement.where((_) => filter!);
      }
      // Apply orderings and limits

      simpleStatement
          .orderBy(orderingBuilders.map((e) => (_) => e.buildTerm()).toList());
      simpleStatement.limit(limit!, offset: offset);

      return _SimpleResult(simpleStatement);
    } else {
      JoinedSelectStatement<T, DT> joinedStatement;
      // If we are only selecting specific columns, we can use a selectOnly statement
      if (targetColumns != null) {
        joinedStatement =
            (db.selectOnly(_tableAsTableInfo, distinct: distinct ?? false)
              ..addColumns(targetColumns));
        // Add the joins to the statement
        joinedStatement =
            joinedStatement.join(joins) as JoinedSelectStatement<T, DT>;
      } else {
        joinedStatement = db
            .select(_tableAsTableInfo, distinct: distinct ?? false)
            .join(joins) as JoinedSelectStatement<T, DT>;
      }
      // Apply the expression to the statement
      if (filter != null) {
        joinedStatement.where(filter!);
      }
      // Apply orderings and limits

      joinedStatement
          .orderBy(orderingBuilders.map((e) => e.buildTerm()).toList());
      joinedStatement.limit(limit!, offset: offset);

      return _JoinedResult(joinedStatement);
    }
  }

  /// Build a select statement based on the manager state
  Selectable<DT> buildSelectStatement() {
    final result = _buildSelectStatement();
    return switch (result) {
      _SimpleResult() => result.statement,
      _JoinedResult() =>
        result.statement.map((p0) => p0.readTable(_tableAsTableInfo))
    };
  }

  /// Build an update statement based on the manager state
  UpdateStatement<T, DT> buildUpdateStatement() {
    final UpdateStatement<T, DT> updateStatement;
    if (joinBuilders.isEmpty) {
      updateStatement = db.update(_tableAsTableInfo);
      if (filter != null) {
        updateStatement.where((_) => filter!);
      }
    } else {
      updateStatement = db.update(_tableAsTableInfo);
      for (var col in _tableAsTableInfo.primaryKey) {
        final subquery =
            _buildSelectStatement(targetColumns: [col]) as _JoinedResult<T, DT>;
        updateStatement.where((tbl) => col.isInQuery(subquery.statement));
      }
    }
    return updateStatement;
  }

  /// Count the number of rows that would be returned by the built statement
  Future<int> count() {
    final count = countAll();
    final result =
        _buildSelectStatement(targetColumns: [count]) as _JoinedResult;
    return result.statement.map((row) => row.read(count)!).getSingle();
  }

  /// Build a delete statement based on the manager state
  DeleteStatement buildDeleteStatement() {
    final DeleteStatement deleteStatement;
    if (joinBuilders.isEmpty) {
      deleteStatement = db.delete(_tableAsTableInfo);
      if (filter != null) {
        deleteStatement.where((_) => filter!);
      }
    } else {
      deleteStatement = db.delete(_tableAsTableInfo);
      for (var col in _tableAsTableInfo.primaryKey) {
        final subquery =
            _buildSelectStatement(targetColumns: [col]) as _JoinedResult<T, DT>;
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
  final TableManagerState<DB, T, DT, FS, OS, C, CI, CU> $state;

  /// Create a new [BaseTableManager] instance
  const BaseTableManager(this.$state);

  /// Deletes all rows matched by built statement
  ///
  /// Returns the amount of rows that were deleted by this statement directly
  /// (not including additional rows that might be affected through triggers or
  /// foreign key constraints).
  Future<int> delete() => $state.buildDeleteStatement().go();

  /// Set the distinct flag on the statement to true
  /// This will ensure that only distinct rows are returned
  C distict() {
    return $state._getChildManagerBuilder($state.copyWith(distinct: true));
  }

  /// Add ordering to the statement
  C orderBy(ComposableOrdering Function(OS o) o) {
    final orderings = o($state.orderingComposer);
    return $state._getChildManagerBuilder($state.copyWith(
        orderingBuilders:
            $state.orderingBuilders.union(orderings.orderingBuilders),
        joinBuilders: $state.joinBuilders.union(orderings.joinBuilders)));
  }

  /// Add a filter to the statement
  C filter(ComposableFilter Function(FS f) f) {
    final filter = f($state.filteringComposer);
    return $state._getChildManagerBuilder($state.copyWith(
        filter: $state.filter == null
            ? filter.expression
            : filter.expression & $state.filter!,
        joinBuilders: $state.joinBuilders.union(filter.joinBuilders)));
  }

  /// Add a limit to the statement
  C limit(int limit, {int? offset}) {
    return $state
        ._getChildManagerBuilder($state.copyWith(limit: limit, offset: offset));
  }

  /// Return the count of rows matched by the built statement
  Future<int> count() => $state.count();

  /// Writes all non-null fields from the entity into the columns of all rows
  /// that match the [filter] clause. Warning: That also means that, when you're
  /// not setting a where clause explicitly, this method will update all rows in
  /// the [$state.table].
  ///
  /// The fields that are null on the entity object will not be changed by
  /// this operation, they will be ignored.
  ///
  /// Returns the amount of rows that have been affected by this operation.
  ///
  /// See also: [RootTableManager.replace], which does not require [filter] statements and
  /// supports setting fields back to null.
  Future<int> write(DT Function(CU o) f) => $state
      .buildUpdateStatement()
      .write(f($state._getUpdateCompanionBuilder) as Insertable<DT>);
}

/// A table manager that can be used to select rows from a table
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
  /// Create a new [ProcessedTableManager] instance
  const ProcessedTableManager(super.$state);

  /// Executes this statement, like [get], but only returns one
  /// value. If the query returns no or too many rows, the returned future will
  /// complete with an error.
  ///
  /// Be aware that this operation won't put a limit clause on this statement,
  /// if that's needed you would have to do use [limit]:
  /// You should only use this method if you know the query won't have more than
  /// one row, for instance because you used `limit(1)` or you know the filters
  /// you've applied will only match one row.
  ///
  /// See also: [getSingleOrNull], which returns `null` instead of
  /// throwing if the query completes with no rows.
  @override
  Future<D> getSingle() => $state.buildSelectStatement().getSingle();

  /// Creates an auto-updating stream of this statement, similar to
  /// [watch]. However, it is assumed that the query will only emit
  /// one result, so instead of returning a `Stream<List<D>>`, this returns a
  /// `Stream<D>`. If, at any point, the query emits no or more than one rows,
  /// an error will be added to the stream instead.
  @override
  Stream<D> watchSingle() => $state.buildSelectStatement().watchSingle();

  /// Executes the statement and returns the first all rows as a list.
  @override
  Future<List<D>> get() => $state.buildSelectStatement().get();

  /// Creates an auto-updating stream of the result that emits new items
  /// whenever any table used in this statement changes.
  @override
  Stream<List<D>> watch() => $state.buildSelectStatement().watch();

  /// Executes this statement, like [get], but only returns one
  /// value. If the result too many values, this method will throw. If no
  /// row is returned, `null` will be returned instead.
  ///
  /// See also: [getSingle], which can be used if the query will
  /// always evaluate to exactly one row.
  @override
  Future<D?> getSingleOrNull() =>
      $state.buildSelectStatement().getSingleOrNull();

  /// Creates an auto-updating stream of this statement, similar to
  /// [watch]. However, it is assumed that the query will only
  /// emit one result, so instead of returning a `Stream<List<D>>`, this
  /// returns a `Stream<D?>`. If the query emits more than one row at
  /// some point, an error will be emitted to the stream instead.
  /// If the query emits zero rows at some point, `null` will be added
  /// to the stream instead.
  @override
  Stream<D?> watchSingleOrNull() =>
      $state.buildSelectStatement().watchSingleOrNull();
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
  /// Create a new [RootTableManager] instance
  const RootTableManager(super.$state);

  /// Select all rows from the table
  C all() => $state._getChildManagerBuilder($state);

  /// Creates a new row in the table using the given function
  ///
  /// By default, an exception will be thrown if another row with the same
  /// primary key already exists. This behavior can be overridden with [mode],
  /// for instance by using [InsertMode.replace] or [InsertMode.insertOrIgnore].
  ///
  /// To apply a partial or custom update in case of a conflict, you can also
  /// use an [upsert clause](https://sqlite.org/lang_UPSERT.html) by using
  /// [onConflict]. See [InsertStatement.insert] for more information.
  ///
  /// By default, the [onConflict] clause will only consider the table's primary
  /// key. If you have additional columns with uniqueness constraints, you have
  /// to manually add them to the clause's [DoUpdate.target].
  ///
  /// Returns the `rowid` of the inserted row. For tables with an auto-increment
  /// column, the `rowid` is the generated value of that column. The returned
  /// value can be inaccurate when [onConflict] is set and the insert behaved
  /// like an update.
  ///
  /// If the table doesn't have a `rowid`, you can't rely on the return value.
  /// Still, the future will always complete with an error if the insert fails.
  Future<int> create(D Function(CI o) f,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) {
    return $state.db.into($state._tableAsTableInfo).insert(
        f($state._getInsertCompanionBuilder) as Insertable<D>,
        mode: mode,
        onConflict: onConflict);
  }

  /// Inserts a row into the table and returns it.
  ///
  /// Depending on the [InsertMode] or the [DoUpdate] `onConflict` clause, the
  /// insert statement may not actually insert a row into the database. Since
  /// this function was declared to return a non-nullable row, it throws an
  /// exception in that case. Use [createReturningOrNull] when performing an
  /// insert with an insert mode like [InsertMode.insertOrIgnore] or when using
  /// a [DoUpdate] with a `where` clause clause.
  Future<D> createReturning(D Function(CI o) f,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) {
    return $state.db.into($state._tableAsTableInfo).insertReturning(
        f($state._getInsertCompanionBuilder) as Insertable<D>,
        mode: mode,
        onConflict: onConflict);
  }

  /// Inserts a row into the table and returns it.
  ///
  /// When no row was inserted and no exception was thrown, for instance because
  /// [InsertMode.insertOrIgnore] was used or because the upsert clause had a
  /// `where` clause that didn't match, `null` is returned instead.
  Future<D?> createReturningOrNull(D Function(CI o) f,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) {
    return $state.db.into($state._tableAsTableInfo).insertReturningOrNull(
        f($state._getInsertCompanionBuilder) as Insertable<D>,
        mode: mode,
        onConflict: onConflict);
  }

  /// Create multiple rows in the table using the given function
  ///
  /// All fields in a row that don't have a default value or auto-increment
  /// must be set and non-null. Otherwise, an [InvalidDataException] will be
  /// thrown.
  /// By default, an exception will be thrown if another row with the same
  /// primary key already exists. This behavior can be overridden with [mode],
  /// for instance by using [InsertMode.replace] or [InsertMode.insertOrIgnore].
  /// Using [bulkCreate] will not disable primary keys or any column constraint
  /// checks.
  /// [onConflict] can be used to create an upsert clause for engines that
  /// support it. For details and examples, see [InsertStatement.insert].
  Future<void> bulkCreate(Iterable<D> Function(CI o) f,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) {
    return $state.db.batch((b) => b.insertAll($state._tableAsTableInfo,
        f($state._getInsertCompanionBuilder) as Iterable<Insertable<D>>,
        mode: mode, onConflict: onConflict));
  }

  /// Replaces the old version of [entity] that is stored in the database with
  /// the fields of the [entity] provided here. This implicitly applies a
  /// [filter] clause to rows with the same primary key as [entity], so that only
  /// the row representing outdated data will be replaced.
  ///
  /// If [entity] has absent values (set to null on the [DataClass] or
  /// explicitly to absent on the [UpdateCompanion]), and a default value for
  /// the field exists, that default value will be used. Otherwise, the field
  /// will be reset to null. This behavior is different to [write], which simply
  /// ignores such fields without changing them in the database.
  ///
  /// Returns true if a row was affected by this operation.
  Future<bool> replace(D entity) {
    return $state.db
        .update($state._tableAsTableInfo)
        .replace(entity as Insertable<D>);
  }
}
