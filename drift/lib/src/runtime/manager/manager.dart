import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/src/runtime/executor/stream_queries.dart';
import 'package:drift/src/runtime/query_builder/query_builder.dart';
import 'package:drift/src/utils/single_transformer.dart';
import 'package:meta/meta.dart';

part 'composer.dart';
part 'filter.dart';
part 'join_builder.dart';
part 'ordering.dart';
part 'references.dart';
part 'annotate.dart';

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
/// The [$CreatePrefetchHooksCallback] refers to the function which the user will use to create a [PrefetchHooks] in `withReferences`
/// See the [BaseReferences] class for more information on how this is used.
///
/// E.G.
/// ```dart
/// users.withReferences((prefetch) => prefetch(group: true))
/// ```
@immutable
class TableManagerState<
    $Database extends GeneratedDatabase,
    $Table extends Table,
    $Dataclass,
    $FilterComposer extends FilterComposer<$Database, $Table>,
    $OrderingComposer extends OrderingComposer<$Database, $Table>,
    $AnnotationComposer extends AnnotationComposer<$Database, $Table>,
    $CreateCompanionCallback extends Function,
    $UpdateCompanionCallback extends Function,
    $DataclassWithReferences,
    $ActiveDataclass,
    $CreatePrefetchHooksCallback extends Function> {
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
  final $FilterComposer Function() createFilteringComposer;

  /// The [OrderingComposer] for this [TableManagerState]
  /// This class will be used to create [OrderingTerm]s
  /// which will be applied to the statement when its eventually created
  final $OrderingComposer Function() createOrderingComposer;

  final $AnnotationComposer Function() createAnnotationComposer;

  /// This function is passed to the user to create a companion
  /// for inserting data into the table
  final $CreateCompanionCallback _createCompanionCallback;

  /// This function is passed to the user to create a companion
  /// for updating data in the table
  final $UpdateCompanionCallback _updateCompanionCallback;

  /// This function is used internally to convert a simple [$Dataclass] into one which has its references attached [$DataclassWithReferences].
  /// This is used internally by [toActiveDataclass] and should not be used outside of this class.
  final List<$DataclassWithReferences> Function(List<TypedResult>)
      _withReferenceMapper;

  final Set<Expression> addedColumns;

  /// This function is used to ensure that the correct dataclass type is returned by the manager.
  ///
  /// Depending on if `withReferences` was called, we will either return a list of [$Dataclass] or [$DataclassWithReferences]
  List<$ActiveDataclass> toActiveDataclass(List<TypedResult> items) {
    if ($DataclassWithReferences == $ActiveDataclass) {
      return _withReferenceMapper(items) as List<$ActiveDataclass>;
    } else {
      return items.map((e) => e.readTable(_tableAsTableInfo)).toList()
          as List<$ActiveDataclass>;
    }
  }

  /// If this table has references, this field will contain the function that the user will use to create a [PrefetchHooks]
  ///
  /// E.G.
  /// If the prefetch function would look like
  /// ```dart
  /// users.withReferences((prefetch) => prefetch(group: true))
  /// ```
  /// Then [_prefetchHooksCallback] would be
  /// ```dart
  /// ({bool group = false}) {
  ///   return PrefetchHooks(...)
  /// }
  /// ```
  final $CreatePrefetchHooksCallback? _prefetchHooksCallback;

  /// Prefetched data, if references with prefetching enabled were added to this manager
  ///
  /// E.G.
  /// ```dart
  /// final (group,refs) = await groups.withReferences((prefetch) => prefetch(users: true)).getSingle();
  /// final users = refs.users.prefetchedData;
  /// /// For references which were not prefetched, this field will be null
  /// final users = refs.admin.prefetchedData; // Returns null
  /// ```
  List<$ActiveDataclass>? get prefetchedData {
    if (_prefetchedData == null) {
      return null;
    }
    return toActiveDataclass(_prefetchedData);
  }

  final List<TypedResult>? _prefetchedData;

  /// Once `withReferences` is called, this field will be set to the function that will be used to get the prefetched data
  late final PrefetchHooks prefetchHooks;

  /// Defines a class which holds the state for a table manager
  /// It contains the database instance, the table instance, and any filters/orderings that will be applied to the query
  /// This is held in a separate class than the [BaseTableManager] so that the state can be passed down from the root manager to the lower level managers
  ///
  /// This class is used internally by the [BaseTableManager] and should not be used directly
  TableManagerState(
      {required this.db,
      required this.table,
      required this.createFilteringComposer,
      required this.createOrderingComposer,
      required this.createAnnotationComposer,
      required $CreateCompanionCallback createCompanionCallback,
      required $UpdateCompanionCallback updateCompanionCallback,
      required List<$DataclassWithReferences> Function(List<TypedResult>)
          withReferenceMapper,
      required $CreatePrefetchHooksCallback? prefetchHooksCallback,
      PrefetchHooks? prefetchHooks,
      List<TypedResult>? prefetchedData,
      this.filter,
      this.distinct,
      this.limit,
      this.offset,
      this.addedColumns = const {},
      this.orderingBuilders = const {},
      this.joinBuilders = const {}})
      : prefetchHooks = prefetchHooks ?? PrefetchHooks(db: db),
        _prefetchedData = prefetchedData,
        _prefetchHooksCallback = prefetchHooksCallback,
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
      $AnnotationComposer,
      $CreateCompanionCallback,
      $UpdateCompanionCallback,
      $DataclassWithReferences,
      $ActiveDataclass,
      $CreatePrefetchHooksCallback> copyWith({
    bool? distinct,
    int? limit,
    int? offset,
    Expression<bool>? filter,
    Set<OrderingBuilder>? orderingBuilders,
    Set<JoinBuilder>? joinBuilders,
    List<$Dataclass>? prefetchedData,
    PrefetchHooks? prefetchHooks,
    Set<Expression>? addedColumns,
  }) {
    /// When we import prefetchedData, it's already in its Row Class,
    /// we need to place it into a TypedResult for the manager to work with it
    final prefetchedDataAsTypedResult = prefetchedData
        ?.map((e) => TypedResult({_tableAsTableInfo: e}, QueryRow({}, db)))
        .toList();

    return TableManagerState(
      db: db,
      table: table,
      createFilteringComposer: createFilteringComposer,
      createOrderingComposer: createOrderingComposer,
      createAnnotationComposer: createAnnotationComposer,
      createCompanionCallback: _createCompanionCallback,
      updateCompanionCallback: _updateCompanionCallback,
      withReferenceMapper: _withReferenceMapper,
      prefetchHooksCallback: _prefetchHooksCallback,
      addedColumns: addedColumns ?? this.addedColumns,
      prefetchedData: prefetchedDataAsTypedResult ?? this._prefetchedData,
      prefetchHooks: prefetchHooks ?? this.prefetchHooks,
      filter: filter ?? this.filter,
      joinBuilders: joinBuilders ?? this.joinBuilders,
      orderingBuilders: orderingBuilders ?? this.orderingBuilders,
      distinct: distinct ?? this.distinct,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  /// When a user calls `withReferences` on a manager, we return a copy which is
  /// set to return a `$DataclassWithReferences` instead of just a `$Dataclass`
  ///
  /// This function is used to make that copy.
  TableManagerState<
      $Database,
      $Table,
      $Dataclass,
      $FilterComposer,
      $OrderingComposer,
      $AnnotationComposer,
      $CreateCompanionCallback,
      $UpdateCompanionCallback,
      $DataclassWithReferences,
      $DataclassWithReferences,
      $CreatePrefetchHooksCallback> copyWithActiveDataclass() {
    return TableManagerState(
      db: db,
      table: table,
      createFilteringComposer: createFilteringComposer,
      createOrderingComposer: createOrderingComposer,
      createAnnotationComposer: createAnnotationComposer,
      createCompanionCallback: _createCompanionCallback,
      updateCompanionCallback: _updateCompanionCallback,
      withReferenceMapper: _withReferenceMapper,
      filter: filter,
      joinBuilders: joinBuilders,
      orderingBuilders: orderingBuilders,
      distinct: distinct,
      limit: limit,
      offset: offset,
      prefetchHooksCallback: _prefetchHooksCallback,
      prefetchedData: _prefetchedData,
      addedColumns: addedColumns,
    );
  }

  /// This method creates a copy of this manager state with a join added to the query.
  ///
  /// If the join already exists in the [joinBuilders], but has `useColumns: false`, we update the JoinBuilder.
  TableManagerState<
          $Database,
          $Table,
          $Dataclass,
          $FilterComposer,
          $OrderingComposer,
          $AnnotationComposer,
          $CreateCompanionCallback,
          $UpdateCompanionCallback,
          $DataclassWithReferences,
          $ActiveDataclass,
          $CreatePrefetchHooksCallback>
      withJoin(
          {required Table currentTable,
          required Table referencedTable,
          required GeneratedColumn currentColumn,
          required GeneratedColumn referencedColumn}) {
    final joinBuilder = JoinBuilder(
        currentTable: currentTable,
        referencedTable: referencedTable,
        currentColumn: currentColumn,
        referencedColumn: referencedColumn,
        useColumns: true);
    // If there is already a join builder for this table, we will replace it
    // to ensure that we have `useColumns` set to true
    final newJoinBuilders = joinBuilders
        .whereNot((element) =>
            element.currentColumn == currentColumn &&
            element.referencedColumn == referencedColumn)
        .toSet()
      ..add(joinBuilder);
    return TableManagerState(
        db: db,
        table: table,
        createFilteringComposer: createFilteringComposer,
        createOrderingComposer: createOrderingComposer,
        createAnnotationComposer: createAnnotationComposer,
        createCompanionCallback: _createCompanionCallback,
        updateCompanionCallback: _updateCompanionCallback,
        withReferenceMapper: _withReferenceMapper,
        filter: filter,
        joinBuilders: newJoinBuilders,
        orderingBuilders: orderingBuilders,
        distinct: distinct,
        limit: limit,
        offset: offset,
        prefetchHooksCallback: _prefetchHooksCallback,
        prefetchedData: _prefetchedData,
        addedColumns: addedColumns);
  }

  /// Helper for getting the table that's casted as a TableInfo
  /// This is needed due to dart's limitations with generics
  TableInfo<$Table, $Dataclass> get _tableAsTableInfo =>
      table as TableInfo<$Table, $Dataclass>;

  /// Builds a select statement with the given target columns, or all columns if none are provided
  JoinedSelectStatement<$Table, $Dataclass> buildSelectStatement(
      {Iterable<Expression>? targetColumns}) {
    final joins = joinBuilders.map((e) => e.buildJoin()).toList();

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

    // Add any additional columns/expression that were added
    joinedStatement.addColumns(addedColumns);

    // If there are any added column, then group by primary key and apply filter to it
    // other wise add the filter to the select directly
    if (addedColumns.isNotEmpty) {
      // ignore: invalid_use_of_visible_for_overriding_member
      joinedStatement.groupBy(table.primaryKey!, having: filter);
    } else if (filter != null) {
      joinedStatement.where(filter!);
    }

    // Apply orderings and limits
    joinedStatement
        .orderBy(orderingBuilders.map((e) => e.buildTerm()).toList());
    if (limit != null) {
      joinedStatement.limit(limit!, offset: offset);
    }

    return joinedStatement;
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
        final subquery = buildSelectStatement(targetColumns: [col]);
        updateStatement.where((tbl) => col.isInQuery(subquery));
      }
    }
    return updateStatement;
  }

  /// Count the number of rows that would be returned by the built statement
  Future<int> count() async {
    final countExpression = countAll();
    final JoinedSelectStatement statement;
    if (joinBuilders.isEmpty) {
      statement = buildSelectStatement(targetColumns: [countExpression]);
    } else {
      final subquery = Subquery(buildSelectStatement(), 'subquery');
      statement = db.selectOnly(subquery)..addColumns([countExpression]);
    }
    return await statement
        .map((row) => row.read(countExpression)!)
        .get()
        .then((value) => value.firstOrNull ?? 0);
  }

  /// Check if any rows exists using the built statement
  Future<bool> exists() async {
    final BaseSelectStatement statement = buildSelectStatement();
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
        final subquery = buildSelectStatement(targetColumns: [col]);
        deleteStatement.where((tbl) => col.isInQuery(subquery));
      }
    }
    return deleteStatement;
  }
}

/// Base class for all table managers
/// Most of this classes functionality is kept in a separate [TableManagerState] class
/// This is so that the state can be passed down to lower level managers
@immutable
abstract class BaseTableManager<
        $Database extends GeneratedDatabase,
        $Table extends Table,
        $Dataclass,
        $FilterComposer extends FilterComposer<$Database, $Table>,
        $OrderingComposer extends OrderingComposer<$Database, $Table>,
        $AnnotationComposer extends AnnotationComposer<$Database, $Table>,
        $CreateCompanionCallback extends Function,
        $UpdateCompanionCallback extends Function,
        $DataclassWithReferences,
        $ActiveDataclass,
        $CreatePrefetchHooksCallback extends Function>
    extends Selectable<$ActiveDataclass> {
  /// The state for this manager
  final TableManagerState<
      $Database,
      $Table,
      $Dataclass,
      $FilterComposer,
      $OrderingComposer,
      $AnnotationComposer,
      $CreateCompanionCallback,
      $UpdateCompanionCallback,
      $DataclassWithReferences,
      $ActiveDataclass,
      $CreatePrefetchHooksCallback> $state;

  /// Create a new [BaseTableManager] instance
  ///
  /// {@macro manager_internal_use_only}
  BaseTableManager(this.$state);

  /// This function with return a new manager which will return each item in the database with its references
  ///
  /// The references are returned as a prefiltered manager, which will only return the items which are related to the item
  ///
  /// For example:
  /// ```dart
  /// for (final (group,refs) in await groups.withReferences().get()) {
  ///   final usersInGroup = await refs.users.get();
  ///   /// Is identical to:
  ///   final usersInGroup = await users.filter((f) => f.group.id(group.id)).get();
  /// }
  /// ```
  /// ### Prefetching
  ///
  /// The keen among you may notice that the above code is extremely inefficient, as it will run a query for each group to get the users in that group.
  /// This could mean hundreds of queries for a single page of data, grinding your application to a halt.
  ///
  /// The solution to this is to use prefetching, which will run a single query to get all the data you need.
  ///
  /// For example:
  /// ```dart
  /// for (final (group,refs) in await groups.withReferences((prefetch) => prefetch(users: true)).get()) {
  ///   final usersInGroup = refs.users.prefetchedData;
  /// }
  /// ```
  ///
  /// Note that `prefetchedData` will be null if the reference was not prefetched.
  ProcessedTableManager<
          $Database,
          $Table,
          $Dataclass,
          $FilterComposer,
          $OrderingComposer,
          $AnnotationComposer,
          $CreateCompanionCallback,
          $UpdateCompanionCallback,
          $DataclassWithReferences,
          $DataclassWithReferences,
          $CreatePrefetchHooksCallback>
      withReferences(
          [final PrefetchHooks Function($CreatePrefetchHooksCallback prefetch)?
              prefetch]) {
    // Build the prefetch hooks based on the user's input
    final prefetchHooks = ($state._prefetchHooksCallback != null)
        ? prefetch?.call($state._prefetchHooksCallback!)
        : null;

    // Return a new manager which is configured to return a
    // `$DataclassWithReferences` instead of a `$Dataclass`
    return ProcessedTableManager($state
        .copyWithActiveDataclass()
        .copyWith(prefetchHooks: prefetchHooks));
  }

  ProcessedTableManager<
          $Database,
          $Table,
          $Dataclass,
          $FilterComposer,
          $OrderingComposer,
          $AnnotationComposer,
          $CreateCompanionCallback,
          $UpdateCompanionCallback,
          $DataclassWithReferences,
          $DataclassWithReferences,
          $CreatePrefetchHooksCallback>
      withAnnotations(Iterable<_BaseAnnotation<Object, $Table>> annotations) {
    final joinBuilders =
        annotations.map((e) => e._joinBuilders).expand((e) => e).toSet();
    final addedColumns = annotations.map((e) => e._expression).toSet();
    return ProcessedTableManager($state.copyWith(
            addedColumns: $state.addedColumns.union(addedColumns),
            joinBuilders: $state.joinBuilders.union(joinBuilders)))
        .withReferences();
  }

  /// Add a limit to the statement
  ProcessedTableManager<
      $Database,
      $Table,
      $Dataclass,
      $FilterComposer,
      $OrderingComposer,
      $AnnotationComposer,
      $CreateCompanionCallback,
      $UpdateCompanionCallback,
      $DataclassWithReferences,
      $ActiveDataclass,
      $CreatePrefetchHooksCallback> limit(int limit, {int? offset}) {
    return ProcessedTableManager($state.copyWith(limit: limit, offset: offset));
  }

  /// Add ordering to the statement
  ProcessedTableManager<
          $Database,
          $Table,
          $Dataclass,
          $FilterComposer,
          $OrderingComposer,
          $AnnotationComposer,
          $CreateCompanionCallback,
          $UpdateCompanionCallback,
          $DataclassWithReferences,
          $ActiveDataclass,
          $CreatePrefetchHooksCallback>
      orderBy(ComposableOrdering Function($OrderingComposer o) o) {
    final composer = $state.createOrderingComposer();

    final orderings = o(composer);
    return ProcessedTableManager($state.copyWith(
        orderingBuilders:
            $state.orderingBuilders.union(orderings.orderingBuilders),
        joinBuilders:
            $state.joinBuilders.union(composer.$joinBuilders.toSet())));
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
      $AnnotationComposer,
      $CreateCompanionCallback,
      $UpdateCompanionCallback,
      $DataclassWithReferences,
      $ActiveDataclass,
      $CreatePrefetchHooksCallback> filter(
    Expression<bool> Function($FilterComposer f) f,
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
          $AnnotationComposer,
          $CreateCompanionCallback,
          $UpdateCompanionCallback,
          $DataclassWithReferences,
          $ActiveDataclass,
          $CreatePrefetchHooksCallback>
      _filter(Expression<bool> Function($FilterComposer f) f,
          _BooleanOperator combineWith) {
    final composer = $state.createFilteringComposer();
    final filter = f(composer);
    final combinedFilter = switch (($state.filter, filter)) {
      (null, var filter) => filter,
      (var filter1, var filter2) => combineWith == _BooleanOperator.and
          ? (filter1!) & (filter2)
          : (filter1!) | (filter2)
    };
    return ProcessedTableManager($state.copyWith(
        filter: combinedFilter,
        joinBuilders:
            $state.joinBuilders.union(composer.$joinBuilders.toSet())));
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
    return $state.copyWith(distinct: distinct).count();
  }

  /// Checks whether any rows exist
  Future<bool> exists() {
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
    return $state.db.transaction(() async {
      /// Fetch the items from the database with the prefetch hooks applied
      var items = await $state.prefetchHooks
          .withJoins($state)
          .copyWith(distinct: distinct, limit: limit, offset: offset)
          .buildSelectStatement()
          .get();

      /// Apply the prefetch hooks to the items
      items = await $state.prefetchHooks.addPrefetchedData(items);
      return $state.toActiveDataclass(items);
    });
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
    /// Build a select statement so we can extract the tables that should be watched
    var baseSelect = $state.prefetchHooks
        .withJoins($state)
        .copyWith(distinct: distinct, limit: limit, offset: offset)
        .buildSelectStatement();
    final context = GenerationContext.fromDb($state.db);
    baseSelect.writeInto(context);

    return $state.db.createStream(QueryStreamFetcher(
      readsFrom: TableUpdateQuery.onAllTables([
        ...context.watchedTables,
        ...$state.prefetchHooks.explicitlyWatchedTables
      ]),
      fetchData: () async {
        return get(distinct: distinct, limit: limit, offset: offset);
      },
    ));
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
    if (list.isEmpty) {
      return null;
    } else {
      return list.single;
    }
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
// As of now this is identical to [BaseTableManager] but it's kept separate for
// future extensibility.
@immutable
class ProcessedTableManager<
        $Database extends GeneratedDatabase,
        $Table extends Table,
        $Dataclass,
        $FilterComposer extends FilterComposer<$Database, $Table>,
        $OrderingComposer extends OrderingComposer<$Database, $Table>,
        $AnnotationComposer extends AnnotationComposer<$Database, $Table>,
        $CreateCompanionCallback extends Function,
        $UpdateCompanionCallback extends Function,
        $DataclassWithReferences,
        $ActiveDataclass,
        $CreatePrefetchHooksCallback extends Function>
    extends BaseTableManager<
        $Database,
        $Table,
        $Dataclass,
        $FilterComposer,
        $OrderingComposer,
        $AnnotationComposer,
        $CreateCompanionCallback,
        $UpdateCompanionCallback,
        $DataclassWithReferences,
        $ActiveDataclass,
        $CreatePrefetchHooksCallback> {
  /// Create a new [ProcessedTableManager] instance
  @internal
  ProcessedTableManager(super.$state);

  /// Prefetched data, if references with prefetching enabled were added to this manager
  ///
  /// E.G.
  /// ```dart
  /// final (group,refs) = await groups.withReferences((prefetch) => prefetch(users: true)).getSingle();
  /// final users = refs.users.prefetchedData;
  /// /// For references which were not prefetched, this field will be null
  /// final users = refs.admin.prefetchedData; // Returns null
  /// ```
  List<$ActiveDataclass>? get prefetchedData => $state.prefetchedData;
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
        $AnnotationComposer extends AnnotationComposer<$Database, $Table>,
        $CreateCompanionCallback extends Function,
        $UpdateCompanionCallback extends Function,
        $DataclassWithReferences,
        $ActiveDataclass,
        $CreatePrefetchHooksCallback extends Function>
    extends BaseTableManager<
        $Database,
        $Table,
        $Dataclass,
        $FilterComposer,
        $OrderingComposer,
        $AnnotationComposer,
        $CreateCompanionCallback,
        $UpdateCompanionCallback,
        $DataclassWithReferences,
        $ActiveDataclass,
        $CreatePrefetchHooksCallback> {
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

  Annotation<T, $Table> annotation<T extends Object>(
    Expression<T> Function($AnnotationComposer a) a,
  ) {
    final composer = $state.createAnnotationComposer();
    final expression = a(composer);
    return Annotation(expression, composer.$joinBuilders.toSet());
  }

  AnnotationWithConverter<DartType, SqlType, $Table>
      annotationWithConverter<DartType, SqlType extends Object>(
    GeneratedColumnWithTypeConverter<DartType, SqlType> Function(
            $AnnotationComposer a)
        a,
  ) {
    final composer = $state.createAnnotationComposer();
    final expression = a(composer);
    return AnnotationWithConverter(expression, composer.$joinBuilders.toSet(),
        converter: (p0) => expression.converter.fromSql(p0));
  }
}
