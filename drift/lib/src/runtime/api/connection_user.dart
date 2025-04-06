part of 'runtime_api.dart';

const _zoneRootUserKey = #DatabaseConnectionUser;

typedef _CustomWriter<T> = Future<T> Function(
    QueryExecutor e, String sql, List<dynamic> vars);

/// Manages a [DatabaseConnection] to send queries to the database.
abstract class DatabaseConnectionUser {
  /// The database connection used by this [DatabaseConnectionUser].
  @protected
  final DatabaseConnection connection;

  /// Whether [doWhenOpened] has been called and completed at least once.
  ///
  /// This can serve as an optimization setups requiring direct access to the
  /// underlying [executor] that want to avoid the asynchronous suspension
  /// around open checks if possible.
  bool _isOpen = false;

  /// The [DriftDatabaseOptions] to use for this database instance.
  ///
  /// Mainly, these options describe how values are mapped from Dart to SQL
  /// values. In the future, they could be expanded to dialect-specific options.
  DriftDatabaseOptions get options => attachedDatabase.options;

  /// A [SqlTypes] mapping configuration to use when mapping values between Dart
  /// and SQL.
  late final SqlTypes typeMapping = options.createTypeMapping(executor.dialect);

  /// The database class that this user is attached to.
  @visibleForOverriding
  GeneratedDatabase get attachedDatabase;

  /// The executor to use when queries are executed.
  QueryExecutor get executor => connection.executor;

  /// Manages active streams from select statements.
  @visibleForTesting
  @protected
  StreamQueryStore get streamQueries => connection.streamQueries;

  /// Constructs a database connection user, which is responsible to store query
  /// streams, wrap the underlying executor and perform type mapping.
  DatabaseConnectionUser(QueryExecutor executor,
      {StreamQueryStore? streamQueries})
      : connection = executor is DatabaseConnection
            ? executor
            : DatabaseConnection(executor, streamQueries: streamQueries);

  /// Creates another [DatabaseConnectionUser] by referencing the implementation
  /// from the [other] user.
  DatabaseConnectionUser.delegate(DatabaseConnectionUser other,
      {QueryExecutor? executor, StreamQueryStore? streamQueries})
      : connection = DatabaseConnection(
          executor ?? other.connection.executor,
          streamQueries: streamQueries ?? other.connection.streamQueries,
        );

  /// Constructs a [DatabaseConnectionUser] that will use the provided
  /// [DatabaseConnection].
  DatabaseConnectionUser.fromConnection(this.connection);

  /// Creates and auto-updating stream from the given select statement. This
  /// method should not be used directly.
  Stream<T> createStream<T extends Object>(QueryStreamFetcher<T> stmt) =>
      resolvedEngine.streamQueries.registerStream(stmt, this);

  /// A, potentially more specific, database engine based on the [Zone] context.
  ///
  /// Inside a [transaction] block, drift will replace this [resolvedEngine]
  /// with an engine specific to the transaction. All other methods on this
  /// class implicitly use the [resolvedEngine] to run their SQL statements.
  /// This lets users call methods on their top-level database or dao class
  /// but run them in a transaction-specific executor.
  @internal
  DatabaseConnectionUser get resolvedEngine {
    final fromZone = Zone.current[_zoneRootUserKey] as DatabaseConnectionUser?;

    if (fromZone != null && fromZone.attachedDatabase == attachedDatabase) {
      return fromZone;
    } else {
      return this;
    }
  }

  /// Marks the [tables] as updated.
  ///
  /// In response to calling this method, all streams listening on any of the
  /// [tables] will load their data again.
  ///
  /// Primarily, this method is meant to be used by drift-internal code. Higher-
  /// level drift APIs will call this method to dispatch stream updates.
  /// Of course, you can also call it yourself to manually dispatch table
  /// updates. To obtain a [TableInfo], use the corresponding getter on the
  /// database class.
  void markTablesUpdated(Iterable<TableInfo> tables) {
    notifyUpdates(
      {for (final table in tables) TableUpdate(table.actualTableName)},
    );
  }

  /// Dispatches the set of [updates] to the stream query manager.
  ///
  /// This method is more specific than [markTablesUpdated] in the presence of
  /// triggers or foreign key constraints. Drift needs to support both when
  /// calculating which streams to update. For instance, consider a simple
  /// database with two tables (`a` and `b`) and a trigger inserting into `b`
  /// after a delete on `a`).
  /// Now, an insert on `a` should not update a stream listening on table `b`,
  /// but a delete should! This additional information is not available with
  /// [markTablesUpdated], so [notifyUpdates] can be used to more efficiently
  /// calculate stream updates in some instances.
  void notifyUpdates(Set<TableUpdate> updates) {
    final withRulesApplied = attachedDatabase.streamUpdateRules.apply(updates);
    resolvedEngine.streamQueries.handleTableUpdates(withRulesApplied);
  }

  /// Listen for table updates reported through [notifyUpdates].
  ///
  /// By default, this listens to every table update. Table updates are reported
  /// as a set of individual updates that happened atomically.
  /// An optional filter can be provided in the [query] parameter. When set,
  /// only updates matching the query will be reported in the stream.
  ///
  /// When called inside a transaction, the stream will close when the
  /// transaction completes or is rolled back. Otherwise, the stream will
  /// complete as the database is closed.
  Stream<Set<TableUpdate>> tableUpdates(
      [TableUpdateQuery query = const TableUpdateQuery.any()]) {
    // The stream should refer to the transaction active when tableUpdates was
    // called, not the one when a listener attaches.
    final engine = resolvedEngine;

    // We're wrapping updatesForSync in a stream controller to make it async.
    return Stream.multi(
      (controller) {
        final source = engine.streamQueries.updatesForSync(query);
        source.pipe(controller);
      },
      isBroadcast: true,
    );
  }

  /// Performs the async [fn] after this executor is ready, or directly if it's
  /// already ready.
  ///
  /// Calling this method directly might circumvent the current transaction. For
  /// that reason, it should only be called inside drift.
  Future<T> doWhenOpened<T>(FutureOr<T> Function(QueryExecutor e) fn) {
    return executor.ensureOpen(attachedDatabase).then((_) {
      _isOpen = true;
      return fn(executor);
    });
  }

  /// Starts an [InsertStatement] for a given table. You can use that statement
  /// to write data into the [table] by using [InsertStatement.insert].
  InsertStatement<T, D> into<T extends Table, D>(TableInfo<T, D> table) {
    return InsertStatement<T, D>(this, table);
  }

  /// Starts an [UpdateStatement] for the given table. You can use that
  /// statement to update individual rows in that table by setting a where
  /// clause on that table and then use [UpdateStatement.write].
  UpdateStatement<Tbl, R> update<Tbl extends Table, R>(
          TableInfo<Tbl, R> table) =>
      UpdateStatement(this, table);

  /// Creates a select statement without a `FROM` clause selecting [columns].
  ///
  /// In SQL, select statements without a table will return a single row where
  /// all the [columns] are evaluated. Of course, columns cannot refer to
  /// columns from a table as these are unavailable without a `FROM` clause.
  ///
  /// To run or watch the select statement, call [Selectable.get] or
  /// [Selectable.watch]. Each returns a list of [TypedResult] rows, for which
  /// a column can be read with [TypedResult.read].
  ///
  /// This example uses [selectExpressions] to query the current time set on the
  /// database server:
  ///
  /// ```dart
  /// final row = await selectExpressions([currentDateAndTime]).getSingle();
  /// final databaseTime = row.read(currentDateAndTime)!;
  /// ```
  BaseSelectStatement<TypedResult> selectExpressions(
      Iterable<Expression> columns) {
    return SelectWithoutTables(this, columns);
  }

  /// Executes a custom delete or update statement and returns the amount of
  /// rows that have been changed.
  /// You can use the [updates] parameter so that drift knows which tables are
  /// affected by your query. All select streams that depend on a table
  /// specified there will then update their data. For more accurate results,
  /// you can also set the [updateKind] parameter to [UpdateKind.delete] or
  /// [UpdateKind.update]. This is optional, but can improve the accuracy of
  /// query updates, especially when using triggers.
  Future<int> customUpdate(
    String query, {
    List<Variable> variables = const [],
    Set<ResultSetImplementation>? updates,
    UpdateKind? updateKind,
  }) async {
    return _customWrite(
      query,
      variables,
      updates,
      updateKind,
      (executor, sql, vars) {
        return executor.runUpdate(sql, vars);
      },
    );
  }

  /// Executes a custom insert statement and returns the last inserted rowid.
  ///
  /// You can tell drift which tables your query is going to affect by using the
  /// [updates] parameter. Query-streams running on any of these tables will
  /// then be re-run.
  Future<int> customInsert(String query,
      {List<Variable> variables = const [],
      Set<ResultSetImplementation>? updates}) {
    return _customWrite(
      query,
      variables,
      updates,
      UpdateKind.insert,
      (executor, sql, vars) {
        return executor.runInsert(sql, vars);
      },
    );
  }

  /// Runs a `INSERT`, `UPDATE` or `DELETE` statement returning rows.
  ///
  /// You can use the [updates] parameter so that drift knows which tables are
  /// affected by your query. All select streams that depend on a table
  /// specified there will then update their data. For more accurate results,
  /// you can also set the [updateKind] parameter.
  /// This is optional, but can improve the accuracy of query updates,
  /// especially when using triggers.
  Future<List<QueryRow>> customWriteReturning(
    String query, {
    List<Variable> variables = const [],
    Set<ResultSetImplementation>? updates,
    UpdateKind? updateKind,
  }) {
    return _customWrite(query, variables, updates, updateKind,
        (executor, sql, vars) async {
      final rows = await executor.runSelect(sql, vars);
      return [for (final row in rows) QueryRow(row, attachedDatabase)];
    });
  }

  /// Common logic for [customUpdate] and [customInsert] which takes care of
  /// mapping the variables, running the query and optionally informing the
  /// stream-queries.
  Future<T> _customWrite<T>(
    String query,
    List<Variable> variables,
    Set<ResultSetImplementation>? updates,
    UpdateKind? updateKind,
    _CustomWriter<T> writer,
  ) async {
    final engine = resolvedEngine;

    final ctx = GenerationContext.fromDb(engine);
    final mappedArgs = variables.map((v) => v.mapToSimpleValue(ctx)).toList();

    final result =
        await engine.doWhenOpened((e) => writer(e, query, mappedArgs));

    if (updates != null) {
      engine.notifyUpdates({
        for (final table in updates)
          TableUpdate(table.entityName, kind: updateKind),
      });
    }

    return result;
  }

  /// Creates a custom select statement from the given sql [query].
  ///
  /// The query can be run once by calling [Selectable.get].
  ///
  /// For an auto-updating query stream, the [readsFrom] parameter needs to be
  /// set to the tables the SQL statement reads from - drift can't infer it
  /// automatically like for other queries constructed with its Dart API.
  /// When, [Selectable.watch] can be used to construct an updating stream.
  ///
  /// For queries that are known to only return a single row,
  /// [Selectable.getSingle] and [Selectable.watchSingle] can be used as well.
  ///
  /// If you use variables in your query (for instance with "?"), they will be
  /// bound to the [variables] you specify on this query.
  Selectable<QueryRow> customSelect(String query,
      {List<Variable> variables = const [],
      Set<ResultSetImplementation> readsFrom = const {}}) {
    return CustomSelectStatement(query, variables, readsFrom, this);
  }

  /// Creates a custom select statement from the given sql [query]. To run the
  /// query once, use [Selectable.get]. For an auto-updating streams, set the
  /// set of tables the ready [readsFrom] and use [Selectable.watch]. If you
  /// know the query will never emit more than one row, you can also use
  /// `getSingle` and `watchSingle` which return the item directly without
  /// wrapping it into a list.
  ///
  /// If you use variables in your query (for instance with "?"), they will be
  /// bound to the [variables] you specify on this query.
  @Deprecated('Renamed to customSelect')
  Selectable<QueryRow> customSelectQuery(String query,
      {List<Variable> variables = const [],
      Set<ResultSetImplementation> readsFrom = const {}}) {
    return customSelect(query, variables: variables, readsFrom: readsFrom);
  }

  /// Runs statements inside a batch.
  ///
  /// A batch can only run a subset of statements, and those statements must be
  /// called on the [Batch] instance. The statements aren't executed with a call
  /// to [Batch]. Instead, all generated queries are queued up and are then run
  /// and executed atomically in a transaction.
  /// If [batch] is called outside of a [transaction] call, it will implicitly
  /// start a transaction. Otherwise, the batch will re-use the transaction,
  /// and will have an effect when the transaction completes.
  /// Typically, running bulk updates (so a lot of similar statements) over a
  /// [Batch] is much faster than running them via the [GeneratedDatabase]
  /// directly.
  ///
  /// An example that inserts users in a batch:
  /// ```dart
  ///  await batch((b) {
  ///    b.insertAll(
  ///      todos,
  ///      [
  ///        TodosCompanion.insert(content: 'Use batches'),
  ///        TodosCompanion.insert(content: 'Have fun'),
  ///      ],
  ///    );
  ///  });
  /// ```
  Future<void> batch(FutureOr<void> Function(Batch batch) runInBatch) {
    final engine = resolvedEngine;

    final batch = Batch._(engine, engine is! Transaction);
    final result = runInBatch(batch);

    if (result is Future) {
      return result.then((_) => batch._commit());
    } else {
      return batch._commit();
    }
  }

  /// Executes [action] with calls intercepted by the given [interceptor]
  ///
  /// This can be used to, for instance, write a custom statement logger or to
  /// retry failing statements automatically.
  Future<T> runWithInterceptor<T>(Future<T> Function() action,
      {required QueryInterceptor interceptor}) async {
    return await resolvedEngine.doWhenOpened((executor) {
      final inner = _ExclusiveExecutor(this,
          executor: executor.interceptWith(interceptor));
      return _runConnectionZoned(inner, action);
    });
  }

  /// Runs [calculation] in a forked [Zone] that has its [resolvedEngine] set
  /// to the [user].
  @protected
  Future<T> _runConnectionZoned<T>(
      DatabaseConnectionUser user, Future<T> Function() calculation) {
    return runZoned(calculation, zoneValues: {_zoneRootUserKey: user});
  }

  /// Will be used by generated code to resolve inline Dart components in sql by
  /// writing the [component].
  @protected
  GenerationContext $write(Component component,
      {bool? hasMultipleTables, int? startIndex}) {
    final context = GenerationContext.fromDb(this)
      ..explicitVariableIndex = startIndex
      ..hasMultipleTables = hasMultipleTables ?? false;
    component.writeInto(context);

    return context;
  }

  /// Writes column names and `VALUES` for an insert statement.
  ///
  /// Used by generated code.
  @protected
  GenerationContext $writeInsertable(TableInfo table, Insertable insertable,
      {int? startIndex}) {
    final context = GenerationContext.fromDb(this)
      ..explicitVariableIndex = startIndex;

    table.validateIntegrity(insertable, isInserting: true);
    InsertStatement(this, table)
        .writeInsertable(context, insertable.toColumns(true));

    return context;
  }

  /// Closes this database and releases associated resources.
  Future<void> close() async {
    await streamQueries.close();
    await executor.close();
  }
}

/// Exposes the private `_runConnectionZoned` method for other parts of drift.
///
/// This is only used by the DevTools extension.
@internal
extension InternalConnectionUserApi on DatabaseConnectionUser {
  /// Call the private [_runConnectionZoned] method.
  Future<T> runConnectionZoned<T>(
      DatabaseConnectionUser user, Future<T> Function() calculation) {
    return _runConnectionZoned(user, calculation);
  }

  Future<T> withCurrentExecutor<T>(Future<T> Function(QueryExecutor e) run) {
    final engine = resolvedEngine;
    return engine.doWhenOpened(run);
  }

  bool get isOpen => _isOpen;
}

class _ExclusiveExecutor extends DatabaseConnectionUser {
  @override
  final GeneratedDatabase attachedDatabase;

  _ExclusiveExecutor(super.other, {super.executor})
      : attachedDatabase = other.attachedDatabase,
        super.delegate();
}
