import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/src/utils/single_transformer.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:meta/meta.dart';

part 'composer.dart';
part 'filter.dart';
part 'composable.dart';
part 'ordering.dart';

/// Defines a class that holds the state for a [BaseTableManager]
///
/// It holds the state for manager of [$Table] table in [$Database] database.
/// It holds the [$FilterComposer] Filters and [$OrderingComposer] Orderings for the manager.
///
/// There are 3 Dataclass generics:
///   - [$Dataclass] is the dataclass that is used to interact with the table
///   - [$DataclassWithReferences] is the dataclass that is returned when the manager is used with the [withReferences] method, this contains the dataclass and any referenced dataclasses
///   - [$ActiveDataclass] is the dataclass that is returned when the manager is used, this is either [$Dataclass] or [$DataclassWithReferences], depending if the manager has had the [withReferences] method called on it
///
/// It also holds the [$CreateCompanionCallback] and [$UpdateCompanionCallback] functions that are used to create companion builders for inserting and updating data.
/// E.G Instead of `CategoriesCompanion.insert(name: "School")` you would use `(f) => f(name: "School")`
///
/// The [$CreatePrefetchedDataGetterCallback] is used by the `withReferences` to set which references should be prefetched. If `withReferences` is called with a prefetch, the getter for the prefetcher
/// will be stores in
///
/// Once a prefetch is ran, the result will be stores as a [$PrefetchedData] object.
@immutable
class TableManagerState<
    $Database extends GeneratedDatabase,
    $Table extends Table,
    $Dataclass,
    $FilterComposer extends FilterComposer<$Database, $Table>,
    $OrderingComposer extends OrderingComposer<$Database, $Table>,
    $CreateCompanionCallback extends Function,
    $UpdateCompanionCallback extends Function,
    $DataclassWithReferences,
    $ActiveDataclass,
    $CreatePrefetchedDataGetterCallback extends Function,
    $PrefetchedData> {
  /// The database used to run the query.
  final $Database db;

  /// The table that the manager is for
  final $Table table;

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
  final $FilterComposer filteringComposer;

  /// The [OrderingComposer] for this [TableManagerState]
  /// This class will be used to create [OrderingTerm]s
  /// which will be applied to the statement when its eventually created
  final $OrderingComposer orderingComposer;

  /// This function is passed to the user to create a companion
  /// for inserting data into the table
  final $CreateCompanionCallback _createCompanionCallback;

  /// This function is passed to the user to create a companion
  /// for updating data in the table
  final $UpdateCompanionCallback _updateCompanionCallback;

  /// This function is used internally to convert a simple [$Dataclass] into one which has its references attached ([$DataclassWithReferences]).
  /// This is used internaly by [toActiveDataclass] and should not be used outside of this class.
  final List<$DataclassWithReferences> Function(
      List<$Dataclass>, $PrefetchedData?) _withReferenceMapper;

  /// This function is used to ensure that the correct dataclass type is returned by the manager.
  /// When `withReferences` is called on a manager, and its `$ActiveDataclass` changes to `$DataclassWithReferences`, this function will do the actual conversion
  /// Every return from the manager should map its results using this function before returning.
  List<$ActiveDataclass> toActiveDataclass(
      List<$Dataclass> items, $PrefetchedData? prefetchedData) {
    if ($DataclassWithReferences == $ActiveDataclass) {
      return _withReferenceMapper(items, prefetchedData)
          as List<$ActiveDataclass>;
    } else {
      return items as List<$ActiveDataclass>;
    }
  }

  /// If this manager was created by a referenced manager with a prefetch.
  /// Then the manager won't run a queries and instead return from this cache
  final List<$Dataclass>? cache;

  /// This field holds the function that is used in the [withReferences] callback.
  /// The result of this callback is stored in [getPrefetchedData] which is responsible for retrieving the prefetched data and
  final $CreatePrefetchedDataGetterCallback?
      _createPrefetchedDataGetterCallback;

  /// If prefetches have been applied to the manager, this field will hold the final function for retrieving the prefetched data
  final Future<$PrefetchedData?> Function(
      TableManagerState<
              $Database,
              $Table,
              $Dataclass,
              $FilterComposer,
              $OrderingComposer,
              $CreateCompanionCallback,
              $UpdateCompanionCallback,
              $DataclassWithReferences,
              $ActiveDataclass,
              $CreatePrefetchedDataGetterCallback,
              $PrefetchedData>
          s)? getPrefetchedData;

  /// Defines a class which holds the state for a table manager
  /// It contains the database instance, the table instance, and any filters/orderings that will be applied to the query
  /// This is held in a seperate class than the [BaseTableManager] so that the state can be passed down from the root manager to the lower level managers
  ///
  /// This class is used internally by the [BaseTableManager] and should not be used directly

  TableManagerState(
      {required this.db,
      required this.table,
      required this.filteringComposer,
      required this.orderingComposer,
      required $CreateCompanionCallback createCompanionCallback,
      required $UpdateCompanionCallback updateCompanionCallback,
      required List<$DataclassWithReferences> Function(
              List<$Dataclass>, $PrefetchedData?)
          withReferenceMapper,
      required $CreatePrefetchedDataGetterCallback?
          createPrefetchedDataGetterCallback,
      this.getPrefetchedData,
      this.cache,
      this.filter,
      this.distinct,
      this.limit,
      this.offset,
      this.orderingBuilders = const {},
      this.joinBuilders = const {}})
      : _createPrefetchedDataGetterCallback =
            createPrefetchedDataGetterCallback,
        _withReferenceMapper = withReferenceMapper,
        _createCompanionCallback = createCompanionCallback,
        _updateCompanionCallback = updateCompanionCallback;

  /// Copy this state with the given values
  TableManagerState<
          $Database,
          $Table,
          $Dataclass,
          $FilterComposer,
          $OrderingComposer,
          $CreateCompanionCallback,
          $UpdateCompanionCallback,
          $DataclassWithReferences,
          $ActiveDataclass,
          $CreatePrefetchedDataGetterCallback,
          $PrefetchedData>
      copyWith(
          {bool? distinct,
          int? limit,
          int? offset,
          Expression<bool>? filter,
          Set<OrderingBuilder>? orderingBuilders,
          Set<JoinBuilder>? joinBuilders,
          List<$Dataclass>? cache,
          Future<$PrefetchedData?> Function(
                  TableManagerState<
                          $Database,
                          $Table,
                          $Dataclass,
                          $FilterComposer,
                          $OrderingComposer,
                          $CreateCompanionCallback,
                          $UpdateCompanionCallback,
                          $DataclassWithReferences,
                          $ActiveDataclass,
                          $CreatePrefetchedDataGetterCallback,
                          $PrefetchedData>
                      s)?
              getPrefetchedData}) {
    return TableManagerState(
      db: db,
      table: table,
      filteringComposer: filteringComposer,
      orderingComposer: orderingComposer,
      createCompanionCallback: _createCompanionCallback,
      updateCompanionCallback: _updateCompanionCallback,
      withReferenceMapper: _withReferenceMapper,
      cache: cache ?? this.cache,
      createPrefetchedDataGetterCallback: _createPrefetchedDataGetterCallback,
      getPrefetchedData: getPrefetchedData ?? this.getPrefetchedData,
      filter: filter ?? this.filter,
      joinBuilders: joinBuilders ?? this.joinBuilders,
      orderingBuilders: orderingBuilders ?? this.orderingBuilders,
      distinct: distinct ?? this.distinct,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// Return a acopy of this state that has the cache removed
  /// This is used whenever filters or orderings are applied to a manager with cache.
  /// We can apply filters or orderings to queries. So the cache is discarded when filters or orderings are applied.
  TableManagerState<
      $Database,
      $Table,
      $Dataclass,
      $FilterComposer,
      $OrderingComposer,
      $CreateCompanionCallback,
      $UpdateCompanionCallback,
      $DataclassWithReferences,
      $ActiveDataclass,
      $CreatePrefetchedDataGetterCallback,
      $PrefetchedData> withInvalidatedCache() {
    return TableManagerState(
      db: db,
      table: table,
      filteringComposer: filteringComposer,
      orderingComposer: orderingComposer,
      createCompanionCallback: _createCompanionCallback,
      updateCompanionCallback: _updateCompanionCallback,
      withReferenceMapper: _withReferenceMapper,
      cache: null,
      createPrefetchedDataGetterCallback: _createPrefetchedDataGetterCallback,
      getPrefetchedData: getPrefetchedData,
      filter: filter,
      joinBuilders: joinBuilders,
      orderingBuilders: orderingBuilders,
      distinct: distinct,
      limit: limit,
      offset: offset,
    );
  }

  /// Create a copy of this state with a new active dataclass
  /// This is used internally to mark a manager for having the mapper applied
  TableManagerState<
      $Database,
      $Table,
      $Dataclass,
      $FilterComposer,
      $OrderingComposer,
      $CreateCompanionCallback,
      $UpdateCompanionCallback,
      $DataclassWithReferences,
      $NewActiveDataclass,
      $CreatePrefetchedDataGetterCallback,
      $PrefetchedData> copyWithNewActiveDataclass<$NewActiveDataclass>() {
    return TableManagerState(
      db: db,
      table: table,
      filteringComposer: filteringComposer,
      orderingComposer: orderingComposer,
      createCompanionCallback: _createCompanionCallback,
      updateCompanionCallback: _updateCompanionCallback,
      withReferenceMapper: _withReferenceMapper,
      filter: filter,
      joinBuilders: joinBuilders,
      orderingBuilders: orderingBuilders,
      distinct: distinct,
      limit: limit,
      offset: offset,
      createPrefetchedDataGetterCallback: _createPrefetchedDataGetterCallback,
      cache: cache,
    );
  }

  /// Helper for getting the table that's casted as a TableInfo
  /// This is needed due to dart's limitations with generics
  TableInfo<$Table, $Dataclass> get _tableAsTableInfo =>
      table as TableInfo<$Table, $Dataclass>;

  /// Builds a select statement with the given target columns, or all columns if none are provided
  _StatementType<$Table, $Dataclass> _buildSelectStatement(
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
      if (limit != null) {
        simpleStatement.limit(limit!, offset: offset);
      }

      return _SimpleResult(simpleStatement);
    } else {
      JoinedSelectStatement<$Table, $Dataclass> joinedStatement;
      // If we are only selecting specific columns, we can use a selectOnly statement
      if (targetColumns != null) {
        joinedStatement =
            (db.selectOnly(_tableAsTableInfo, distinct: distinct ?? false)
              ..addColumns(targetColumns));
        // Add the joins to the statement
        joinedStatement = joinedStatement.join(joins)
            as JoinedSelectStatement<$Table, $Dataclass>;
      } else {
        joinedStatement = db
            .select(_tableAsTableInfo, distinct: distinct ?? false)
            .join(joins) as JoinedSelectStatement<$Table, $Dataclass>;
      }
      // Apply the expression to the statement
      if (filter != null) {
        joinedStatement.where(filter!);
      }

      // Apply orderings and limits
      joinedStatement
          .orderBy(orderingBuilders.map((e) => e.buildTerm()).toList());
      if (limit != null) {
        joinedStatement.limit(limit!, offset: offset);
      }

      return _JoinedResult(joinedStatement);
    }
  }

  /// Build a select statement based on the manager state
  Selectable<$Dataclass> buildSelectStatement() {
    final result = _buildSelectStatement();
    switch (result) {
      case _SimpleResult():
        return result.statement;
      case _JoinedResult():
        return result.statement.map((p0) => p0.readTable(_tableAsTableInfo));
    }
  }

  /// Build an update statement based on the manager state
  UpdateStatement<$Table, $Dataclass> buildUpdateStatement() {
    final UpdateStatement<$Table, $Dataclass> updateStatement;
    if (joinBuilders.isEmpty) {
      updateStatement = db.update(_tableAsTableInfo);
      if (filter != null) {
        updateStatement.where((_) => filter!);
      }
    } else {
      updateStatement = db.update(_tableAsTableInfo);
      for (var col in _tableAsTableInfo.primaryKey) {
        final subquery = _buildSelectStatement(targetColumns: [col])
            as _JoinedResult<$Table, $Dataclass>;
        updateStatement.where((tbl) => col.isInQuery(subquery.statement));
      }
    }
    return updateStatement;
  }

  /// Count the number of rows that would be returned by the built statement
  Future<int> count() async {
    final countExpression = countAll();
    final JoinedSelectStatement statement;
    if (joinBuilders.isEmpty) {
      statement = ((_buildSelectStatement(targetColumns: [countExpression])
              as _JoinedResult)
          .statement);
    } else {
      final subquery = Subquery(
          ((_buildSelectStatement() as _JoinedResult).statement), 'subquery');
      statement = db.selectOnly(subquery)..addColumns([countExpression]);
    }
    return await statement
        .map((row) => row.read(countExpression)!)
        .get()
        .then((value) => value.firstOrNull ?? 0);
  }

  /// Check if any rows exists using the built statement
  Future<bool> exists() async {
    final result = _buildSelectStatement();
    final BaseSelectStatement statement;
    switch (result) {
      case _SimpleResult():
        statement = result.statement;
      case _JoinedResult():
        statement = result.statement;
    }
    final query = existsQuery(statement);
    final existsStatement = db.selectOnly(_tableAsTableInfo)
      ..addColumns([query]);
    return (await existsStatement
        .map((p0) => p0.read(query))
        .get()
        .then((value) {
      return value.firstOrNull ?? false;
    }));
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
        final subquery = _buildSelectStatement(targetColumns: [col])
            as _JoinedResult<$Table, $Dataclass>;
        deleteStatement.where((tbl) => col.isInQuery(subquery.statement));
      }
    }
    return deleteStatement;
  }
}

/// Base class for all table managers
/// Most of this classes functionality is kept in a seperate [TableManagerState] class
/// This is so that the state can be passed down to lower level managers
@immutable
abstract class BaseTableManager<
    $Database extends GeneratedDatabase,
    $Table extends Table,
    $Dataclass,
    $FilterComposer extends FilterComposer<$Database, $Table>,
    $OrderingComposer extends OrderingComposer<$Database, $Table>,
    $CreateCompanionCallback extends Function,
    $UpdateCompanionCallback extends Function,
    $DataclassWithReferences,
    $ActiveDataclass,
    $CreatePrefetchedDataGetterCallback extends Function,
    $PrefetchedData> extends Selectable<$ActiveDataclass> {
  /// The state for this manager
  final TableManagerState<
      $Database,
      $Table,
      $Dataclass,
      $FilterComposer,
      $OrderingComposer,
      $CreateCompanionCallback,
      $UpdateCompanionCallback,
      $DataclassWithReferences,
      $ActiveDataclass,
      $CreatePrefetchedDataGetterCallback,
      $PrefetchedData> $state;

  /// Create a new [BaseTableManager] instance
  ///
  /// {@macro manager_internal_use_only}
  BaseTableManager(this.$state);

  /// Returns a manager which will return each row along with prefiltered managers for the referenced tables
  ///
  /// E.G
  /// ```dart
  /// final usersWithReferences = await db.users.withReferences().get();
  /// for (final userWithReferences in usersWithReferences) {
  ///   final user = userWithReferences.user;
  ///   final profile = await userWithReferences.profile.getSingle();
  /// }
  ///
  /// Note: Using this method incorrectly can lead to N+1 queries, where each row in the result set triggers a new query.
  /// Use this method with caution and always profile your queries to ensure they are efficient.
  ///
  /// TODO: More docs for prefetch
  ProcessedTableManager<
          $Database,
          $Table,
          $Dataclass,
          $FilterComposer,
          $OrderingComposer,
          $CreateCompanionCallback,
          $UpdateCompanionCallback,
          $DataclassWithReferences,
          $DataclassWithReferences,
          $CreatePrefetchedDataGetterCallback,
          $PrefetchedData>
      withReferences(
          [Future<$PrefetchedData> Function(
                      $Database, List<$DataclassWithReferences>)
                  Function($CreatePrefetchedDataGetterCallback o)?
              prefetch]) {
    final stateWithGetPrefetched = $state.copyWith(
      getPrefetchedData: <T>(TableManagerState<
              $Database,
              $Table,
              $Dataclass,
              $FilterComposer,
              $OrderingComposer,
              $CreateCompanionCallback,
              $UpdateCompanionCallback,
              $DataclassWithReferences,
              T,
              $CreatePrefetchedDataGetterCallback,
              $PrefetchedData>
          state) async {
        if (state._createPrefetchedDataGetterCallback == null) {
          return null;
        }
        return await prefetch?.call(state._createPrefetchedDataGetterCallback)(
            state.db,
            await state
                .buildSelectStatement()
                .get()
                .then((items) => $state._withReferenceMapper(items, null)));
      },
    );

    if ($DataclassWithReferences == $ActiveDataclass) {
      return ProcessedTableManager(stateWithGetPrefetched as TableManagerState<
          $Database,
          $Table,
          $Dataclass,
          $FilterComposer,
          $OrderingComposer,
          $CreateCompanionCallback,
          $UpdateCompanionCallback,
          $DataclassWithReferences,
          $DataclassWithReferences,
          $CreatePrefetchedDataGetterCallback,
          $PrefetchedData>);
    }
    return ProcessedTableManager(stateWithGetPrefetched
        .copyWithNewActiveDataclass<$DataclassWithReferences>());
  }

  /// Add a limit to the statement
  ProcessedTableManager<
      $Database,
      $Table,
      $Dataclass,
      $FilterComposer,
      $OrderingComposer,
      $CreateCompanionCallback,
      $UpdateCompanionCallback,
      $DataclassWithReferences,
      $ActiveDataclass,
      $CreatePrefetchedDataGetterCallback,
      $PrefetchedData> limit(int limit, {int? offset}) {
    return ProcessedTableManager(
        $state.copyWith(limit: limit, offset: offset).withInvalidatedCache());
  }

  /// Add ordering to the statement
  ProcessedTableManager<
          $Database,
          $Table,
          $Dataclass,
          $FilterComposer,
          $OrderingComposer,
          $CreateCompanionCallback,
          $UpdateCompanionCallback,
          $DataclassWithReferences,
          $ActiveDataclass,
          $CreatePrefetchedDataGetterCallback,
          $PrefetchedData>
      orderBy(ComposableOrdering Function($OrderingComposer o) o) {
    final orderings = o($state.orderingComposer);
    return ProcessedTableManager($state
        .copyWith(
            orderingBuilders:
                $state.orderingBuilders.union(orderings.orderingBuilders),
            joinBuilders: $state.joinBuilders.union(orderings.joinBuilders))
        .withInvalidatedCache());
  }

  /// Add a filter to the statement
  ///
  /// Any filters that were previously applied will be combined with an AND operator
  ProcessedTableManager<
      $Database,
      $Table,
      $Dataclass,
      $FilterComposer,
      $OrderingComposer,
      $CreateCompanionCallback,
      $UpdateCompanionCallback,
      $DataclassWithReferences,
      $ActiveDataclass,
      $CreatePrefetchedDataGetterCallback,
      $PrefetchedData> filter(
    ComposableFilter Function($FilterComposer f) f,
  ) {
    return _filter(f, _BooleanOperator.and);
  }

  /// Add a filter to the statement
  ///
  /// The [combineWith] parameter can be used to specify how the new filter should be combined with the existing filter
  ProcessedTableManager<
          $Database,
          $Table,
          $Dataclass,
          $FilterComposer,
          $OrderingComposer,
          $CreateCompanionCallback,
          $UpdateCompanionCallback,
          $DataclassWithReferences,
          $ActiveDataclass,
          $CreatePrefetchedDataGetterCallback,
          $PrefetchedData>
      _filter(ComposableFilter Function($FilterComposer f) f,
          _BooleanOperator combineWith) {
    final filter = f($state.filteringComposer);
    final combinedFilter = switch (($state.filter, filter.expression)) {
      (null, null) => null,
      (null, var filter) => filter,
      (var filter, null) => filter,
      (var filter1, var filter2) => combineWith == _BooleanOperator.and
          ? (filter1!) & (filter2!)
          : (filter1!) | (filter2!)
    };
    return ProcessedTableManager($state
        .copyWith(
            filter: combinedFilter,
            joinBuilders: $state.joinBuilders.union(filter.joinBuilders))
        .withInvalidatedCache());
  }

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
  Future<int> update(
          Insertable<$Dataclass> Function($UpdateCompanionCallback o) f) =>
      $state.buildUpdateStatement().write(f($state._updateCompanionCallback));

  /// Return the count of rows matched by the built statement
  /// When counting rows, the query will only count distinct rows by default
  Future<int> count({bool distinct = true}) {
    if ($state.cache != null) {
      return Future.value($state.cache!.length);
    }
    return $state.copyWith(distinct: distinct).count();
  }

  /// Checks whether any rows exist
  Future<bool> exists() {
    if ($state.cache != null) {
      return Future.value($state.cache!.isNotEmpty);
    }

    return $state.exists();
  }

  /// Deletes all rows matched by built statement
  ///
  /// Returns the amount of rows that were deleted by this statement directly
  /// (not including additional rows that might be affected through triggers or
  /// foreign key constraints).
  Future<int> delete() => $state.buildDeleteStatement().go();

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
  ///
  /// The [distinct] parameter (enabled by default) controls whether to generate
  /// a `SELECT DISTINCT` query, removing duplicates from the result.
  @override
  Future<$ActiveDataclass> getSingle({bool distinct = true}) async =>
      (await get(distinct: distinct)).single;

  /// Creates an auto-updating stream of this statement, similar to
  /// [watch]. However, it is assumed that the query will only emit
  /// one result, so instead of returning a `Stream<List<D>>`, this returns a
  /// `Stream<D>`. If, at any point, the query emits no or more than one rows,
  /// an error will be added to the stream instead.
  ///
  /// The [distinct] parameter (enabled by default) controls whether to generate
  /// a `SELECT DISTINCT` query, removing duplicates from the result.
  @override
  Stream<$ActiveDataclass> watchSingle({bool distinct = true}) =>
      watch(distinct: distinct).transform(singleElements());

  /// Executes the statement and returns all rows as a list.
  ///
  /// Use [limit] and [offset] to limit the number of rows returned
  /// An offset will only be applied if a limit is also set
  ///
  /// The [distinct] parameter (disabled by default) controls whether to generate
  /// a `SELECT DISTINCT` query, removing duplicates from the result.
  @override
  Future<List<$ActiveDataclass>> get(
      {bool distinct = false, int? limit, int? offset}) async {
    final prefetchedData = await $state.getPrefetchedData?.call($state);
    if ($state.cache != null) {
      return Future.value(
          $state.toActiveDataclass($state.cache!, prefetchedData));
    }
    return $state
        .copyWith(distinct: distinct, limit: limit, offset: offset)
        .buildSelectStatement()
        .get()
        .then((v) => $state.toActiveDataclass(v, prefetchedData));
  }

  /// Creates an auto-updating stream of the result that emits new items
  /// whenever any table used in this statement changes.
  ///
  /// Use [limit] and [offset] to limit the number of rows returned
  /// An offset will only be applied if a limit is also set
  ///
  /// The [distinct] parameter (disabled by default) controls whether to generate
  /// a `SELECT DISTINCT` query, removing duplicates from the result.
  @override
  Stream<List<$ActiveDataclass>> watch(
      {bool distinct = false, int? limit, int? offset}) {
    final prefetchedDataStream =
        $state.getPrefetchedData?.call($state).asStream() ?? Stream.value(null);
    final dataclassStream = $state.cache != null
        ? Stream.value($state.cache!)
        : $state
            .copyWith(
              distinct: distinct,
              limit: limit,
              offset: offset,
              cache: $state.cache,
            )
            .buildSelectStatement()
            .watch();
    return prefetchedDataStream.combineLatest(
        dataclassStream, (p0, p1) => $state.toActiveDataclass(p1, p0));
  }

  /// Executes this statement, like [get], but only returns one
  /// value. If the result too many values, this method will throw. If no
  /// row is returned, `null` will be returned instead.
  ///
  /// See also: [getSingle], which can be used if the query will
  /// always evaluate to exactly one row.
  ///
  /// The [distinct] parameter (enabled by default) controls whether to generate
  /// a `SELECT DISTINCT` query, removing duplicates from the result.
  @override
  Future<$ActiveDataclass?> getSingleOrNull({bool distinct = true}) async {
    final list = await get(distinct: distinct);
    final iterator = list.iterator;

    if (!iterator.moveNext()) {
      return null;
    }
    final element = iterator.current;
    if (iterator.moveNext()) {
      throw StateError('Expected exactly one result, but found more than one!');
    }
    return element;
  }

  /// Creates an auto-updating stream of this statement, similar to
  /// [watch]. However, it is assumed that the query will only
  /// emit one result, so instead of returning a `Stream<List<D>>`, this
  /// returns a `Stream<D?>`. If the query emits more than one row at
  /// some point, an error will be emitted to the stream instead.
  /// If the query emits zero rows at some point, `null` will be added
  /// to the stream instead.
  ///
  /// The [distinct] parameter (enabled by default) controls whether to generate
  /// a `SELECT DISTINCT` query, removing duplicates from the result.
  @override
  Stream<$ActiveDataclass?> watchSingleOrNull({bool distinct = true}) =>
      watch(distinct: distinct).transform(singleElementsOrNull());
}

/// A table manager that exposes methods to a table manager that already has
/// filters/orderings/limit applied.
///
/// Some methods, like [RootTableManager.create] are intentionally not present
/// on [ProcessedTableManager] because combining e.g. [BaseTableManager.filter]
/// with [RootTableManager.create] makes little sense - there is no `WHERE`
/// clause on inserts.
/// By introducing a separate interface for managers with filters applied to
/// them, the API doesn't allow combining incompatible clauses and operations.
///
// As of now this is identical to [BaseTableManager] but it's kept seperate for
// future extensibility.
@immutable
class ProcessedTableManager<
        $Database extends GeneratedDatabase,
        $Table extends Table,
        $Dataclass,
        $FilterComposer extends FilterComposer<$Database, $Table>,
        $OrderingComposer extends OrderingComposer<$Database, $Table>,
        $CreateCompanionCallback extends Function,
        $UpdateCompanionCallback extends Function,
        $DataclassWithReferences,
        $ActiveDataclass,
        $CreatePrefetchedDataGetterCallback extends Function,
        $PrefetchedData>
    extends BaseTableManager<
        $Database,
        $Table,
        $Dataclass,
        $FilterComposer,
        $OrderingComposer,
        $CreateCompanionCallback,
        $UpdateCompanionCallback,
        $DataclassWithReferences,
        $ActiveDataclass,
        $CreatePrefetchedDataGetterCallback,
        $PrefetchedData> {
  /// Create a new [ProcessedTableManager] instance
  @internal
  ProcessedTableManager(super.$state);
}

/// A table manager with top level function for creating, reading, updating, and
/// deleting items.
@immutable
abstract class RootTableManager<
        $Database extends GeneratedDatabase,
        $Table extends Table,
        $Dataclass,
        $FilterComposer extends FilterComposer<$Database, $Table>,
        $OrderingComposer extends OrderingComposer<$Database, $Table>,
        $CreateCompanionCallback extends Function,
        $UpdateCompanionCallback extends Function,
        $DataclassWithReferences,
        $ActiveDataclass,
        $CreatePrefetchedDataGetterCallback extends Function,
        $PrefetchedData>
    extends BaseTableManager<
        $Database,
        $Table,
        $Dataclass,
        $FilterComposer,
        $OrderingComposer,
        $CreateCompanionCallback,
        $UpdateCompanionCallback,
        $DataclassWithReferences,
        $ActiveDataclass,
        $CreatePrefetchedDataGetterCallback,
        $PrefetchedData> {
  /// Create a new [RootTableManager] instance
  ///
  /// {@template manager_internal_use_only}
  /// This class is implemented by the code generator and should
  /// not be instantiated or extended manually.
  /// {@endtemplate}
  RootTableManager(super.$state);

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
  Future<int> create(
      Insertable<$Dataclass> Function($CreateCompanionCallback o) f,
      {InsertMode? mode,
      UpsertClause<$Table, $Dataclass>? onConflict}) {
    return $state.db.into($state._tableAsTableInfo).insert(
        f($state._createCompanionCallback),
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
  Future<$Dataclass> createReturning(
      Insertable<$Dataclass> Function($CreateCompanionCallback o) f,
      {InsertMode? mode,
      UpsertClause<$Table, $Dataclass>? onConflict}) {
    return $state.db.into($state._tableAsTableInfo).insertReturning(
        f($state._createCompanionCallback),
        mode: mode,
        onConflict: onConflict);
  }

  /// Inserts a row into the table and returns it.
  ///
  /// When no row was inserted and no exception was thrown, for instance because
  /// [InsertMode.insertOrIgnore] was used or because the upsert clause had a
  /// `where` clause that didn't match, `null` is returned instead.
  Future<$Dataclass?> createReturningOrNull(
      Insertable<$Dataclass> Function($CreateCompanionCallback o) f,
      {InsertMode? mode,
      UpsertClause<$Table, $Dataclass>? onConflict}) {
    return $state.db.into($state._tableAsTableInfo).insertReturningOrNull(
        f($state._createCompanionCallback),
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
  Future<void> bulkCreate(
      Iterable<Insertable<$Dataclass>> Function($CreateCompanionCallback o) f,
      {InsertMode? mode,
      UpsertClause<$Table, $Dataclass>? onConflict}) {
    return $state.db.batch((b) => b.insertAll(
        $state._tableAsTableInfo, f($state._createCompanionCallback),
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
  /// will be reset to null. This behavior is different to [update], which simply
  /// ignores such fields without changing them in the database.
  ///
  /// Returns true if a row was affected by this operation.
  Future<bool> replace(Insertable<$Dataclass> entity) {
    return $state.db.update($state._tableAsTableInfo).replace(entity);
  }

  /// Replace multiple rows in the table
  ///
  /// If any of the [entities] has an absent value (set to null on the [DataClass] or
  /// explicitly to absent on the [UpdateCompanion]), and a default value for
  /// the field exists, that default value will be used. Otherwise, the field
  /// will be reset to null. This behavior is different to [update], which simply
  /// ignores such fields without changing them in the database.
  Future<void> bulkReplace(Iterable<Insertable<$Dataclass>> entities) {
    return $state.db
        .batch((b) => b.replaceAll($state._tableAsTableInfo, entities));
  }
}

/// This sealed class is used to hold a query which may or may not be a joined query
sealed class _StatementType<T extends Table, DT> {
  const _StatementType();
}

class _SimpleResult<T extends Table, DT> extends _StatementType<T, DT> {
  final SimpleSelectStatement<T, DT> statement;
  const _SimpleResult(this.statement);
}

class _JoinedResult<T extends Table, DT> extends _StatementType<T, DT> {
  final JoinedSelectStatement<T, DT> statement;

  const _JoinedResult(this.statement);
}

/// Base class for the "WithReferece" classes that
class BaseWithReferences<$Database extends GeneratedDatabase, $Dataclass,
    $PrefetchedData> {
  /// The database instance
  // ignore: non_constant_identifier_names
  final $Database $_db;

  /// The dataclass these references are for
  // ignore: non_constant_identifier_names
  final $Dataclass $_item;

  /// The prefetched data of the manager which created this class
  // ignore: non_constant_identifier_names
  final $PrefetchedData? $_prefetchedData;

  /// Create a [BaseWithReferences] class
  // ignore: non_constant_identifier_names
  BaseWithReferences(this.$_db, this.$_item, [this.$_prefetchedData]);
}

/// This function is used internally to prefetch all the rows for a single reference.
/// It's used by the generated code to combine referenced managers into a single manager that
/// returns all the referenced objects and then retreives the data.
///
/// {@macro manager_internal_use_only}
Future<List<$Dataclass>?>
    prefetchRelatedField<$Dataclass, $DataclassWithReferences>(
        List<$DataclassWithReferences> refs,
        ProcessedTableManager<dynamic, dynamic, $Dataclass, dynamic, dynamic,
                    dynamic, dynamic, dynamic, $Dataclass, dynamic, dynamic>
                Function($DataclassWithReferences)
            referencedManager,
        {required bool prefetch}) async {
  if (prefetch && refs.isNotEmpty) {
    final managers = refs.map(referencedManager);
    final manager = managers.reduce((value, element) => value._filter(
        (_) => ComposableFilter._(element.$state.filter, {}),
        _BooleanOperator.or));
    return await manager.get();
  } else {
    return null;
  }
}
