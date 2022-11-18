part of 'runtime_api.dart';

const _zoneRootUserKey = #DatabaseConnectionUser;

typedef _CustomWriter<T> = Future<T> Function(
    QueryExecutor e, String sql, List<dynamic> vars);

/// Manages a [DatabaseConnection] to send queries to the database.
abstract class DatabaseConnectionUser {
  /// The database connection used by this [DatabaseConnectionUser].
  @protected
  final DatabaseConnection connection;

  /// The [DriftDatabaseOptions] to use for this database instance.
  ///
  /// Mainly, these options describe how values are mapped from Dart to SQL
  /// values. In the future, they could be expanded to dialect-specific options.
  DriftDatabaseOptions get options => attachedDatabase.options;

  /// A [SqlTypes] mapping configuration to use when mapping values between Dart
  /// and SQL.
  SqlTypes get typeMapping => options.createTypeMapping(executor.dialect);

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
      : connection = DatabaseConnection(executor, streamQueries: streamQueries);

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
  Stream<List<Map<String, Object?>>> createStream(QueryStreamFetcher stmt) =>
      streamQueries.registerStream(stmt);

  /// Creates a copy of the table with an alias so that it can be used in the
  /// same query more than once.
  ///
  /// Example which uses the same table (here: points) more than once to
  /// differentiate between the start and end point of a route:
  /// ```
  /// var source = alias(points, 'source');
  /// var destination = alias(points, 'dest');
  ///
  /// select(routes).join([
  ///   innerJoin(source, routes.startPoint.equalsExp(source.id)),
  ///   innerJoin(destination, routes.startPoint.equalsExp(destination.id)),
  /// ]);
  /// ```
  T alias<T, D>(ResultSetImplementation<T, D> table, String alias) {
    return table.createAlias(alias).asDslTable;
  }

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
    return executor.ensureOpen(attachedDatabase).then((_) => fn(executor));
  }

  /// Starts an [InsertStatement] for a given table. You can use that statement
  /// to write data into the [table] by using [InsertStatement.insert].
  InsertStatement<T, D> into<T extends Table, D>(TableInfo<T, D> table) {
    return InsertStatement<T, D>(resolvedEngine, table);
  }

  /// Starts an [UpdateStatement] for the given table. You can use that
  /// statement to update individual rows in that table by setting a where
  /// clause on that table and then use [UpdateStatement.write].
  UpdateStatement<Tbl, R> update<Tbl extends Table, R>(
          TableInfo<Tbl, R> table) =>
      UpdateStatement(resolvedEngine, table);

  /// Starts a query on the given table.
  ///
  /// In drift, queries are commonly used as a builder by chaining calls on them
  /// using the `..` syntax from Dart. For instance, to load the 10 oldest users
  /// with an 'S' in their name, you could use:
  /// ```dart
  /// Future<List<User>> oldestUsers() {
  ///   return (
  ///     select(users)
  ///       ..where((u) => u.name.like('%S%'))
  ///       ..orderBy([(u) => OrderingTerm(
  ///         expression: u.id,
  ///         mode: OrderingMode.asc
  ///       )])
  ///       ..limit(10)
  ///   ).get();
  /// }
  /// ```
  ///
  /// The [distinct] parameter (defaults to false) can be used to remove
  /// duplicate rows from the result set.
  ///
  /// For more information on queries, see the
  /// [documentation](https://drift.simonbinder.eu/docs/getting-started/writing_queries/).
  SimpleSelectStatement<T, R> select<T extends HasResultSet, R>(
      ResultSetImplementation<T, R> table,
      {bool distinct = false}) {
    return SimpleSelectStatement<T, R>(resolvedEngine, table,
        distinct: distinct);
  }

  /// Starts a complex statement on [table] that doesn't necessarily use all of
  /// [table]'s columns.
  ///
  /// Unlike [select], which automatically selects all columns of [table], this
  /// method is suitable for more advanced queries that can use [table] without
  /// using their column. As an example, assuming we have a table `comments`
  /// with a `TextColumn content`, this query would report the average length of
  /// a comment:
  /// ```dart
  /// Stream<num> watchAverageCommentLength() {
  ///   final avgLength = comments.content.length.avg();
  ///   final query = selectWithoutResults(comments)
  ///     ..addColumns([avgLength]);
  ///
  ///   return query.map((row) => row.read(avgLength)).watchSingle();
  /// }
  /// ```
  ///
  /// While this query reads from `comments`, it doesn't use all of it's columns
  /// (in fact, it uses none of them!). This makes it suitable for
  /// [selectOnly] instead of [select].
  ///
  /// The [distinct] parameter (defaults to false) can be used to remove
  /// duplicate rows from the result set.
  ///
  /// For simple queries, use [select].
  ///
  /// See also:
  ///  - the documentation on [aggregate expressions](https://drift.simonbinder.eu/docs/getting-started/expressions/#aggregate)
  ///  - the documentation on [group by](https://drift.simonbinder.eu/docs/advanced-features/joins/#group-by)
  JoinedSelectStatement<T, R> selectOnly<T extends HasResultSet, R>(
      ResultSetImplementation<T, R> table,
      {bool distinct = false}) {
    return JoinedSelectStatement<T, R>(
        resolvedEngine, table, [], distinct, false, false);
  }

  /// Starts a [DeleteStatement] that can be used to delete rows from a table.
  ///
  /// See the [documentation](https://drift.simonbinder.eu/docs/getting-started/writing_queries/#updates-and-deletes)
  /// for more details and example on how delete statements work.
  DeleteStatement<T, D> delete<T extends Table, D>(TableInfo<T, D> table) {
    return DeleteStatement<T, D>(resolvedEngine, table);
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
    Set<TableInfo>? updates,
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
      {List<Variable> variables = const [], Set<TableInfo>? updates}) {
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
    Set<TableInfo>? updates,
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
    Set<TableInfo>? updates,
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
          TableUpdate(table.actualTableName, kind: updateKind),
      });
    }

    return result;
  }

  /// Creates a custom select statement from the given sql [query]. To run the
  /// query once, use [Selectable.get]. For an auto-updating streams, set the
  /// set of tables the ready [readsFrom] and use [Selectable.watch]. If you
  /// know the query will never emit more than one row, you can also use
  /// `getSingle` and `SelectableUtils.watchSingle` which return the item
  /// directly without wrapping it into a list.
  ///
  /// If you use variables in your query (for instance with "?"), they will be
  /// bound to the [variables] you specify on this query.
  Selectable<QueryRow> customSelect(String query,
      {List<Variable> variables = const [],
      Set<ResultSetImplementation> readsFrom = const {}}) {
    return CustomSelectStatement(query, variables, readsFrom, resolvedEngine);
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

  /// Executes the custom sql [statement] on the database.
  ///
  /// [statement] should contain exactly one SQL statement. Attempting to run
  /// multiple statements with a single [customStatement] may not be fully
  /// supported on all platforms.
  Future<void> customStatement(String statement, [List<dynamic>? args]) {
    final engine = resolvedEngine;

    return engine.doWhenOpened((executor) {
      return executor.runCustom(statement, args);
    });
  }

  /// Executes [action] in a transaction, which means that all its queries and
  /// updates will be called atomically.
  ///
  /// Returns the value of [action].
  /// When [action] throws an exception, the transaction will be reset and no
  /// changes will be applied to the databases. The exception will be rethrown
  /// by [transaction].
  ///
  /// The behavior of stream queries in transactions depends on where the stream
  /// was created:
  ///
  /// - streams created outside of a [transaction] block: The stream will update
  ///   with the tables modified in the transaction after it completes
  ///   successfully. If the transaction fails, the stream will not update.
  /// - streams created inside a [transaction] block: The stream will update for
  ///   each write in the transaction. When the transaction completes,
  ///   successful or not, streams created in it will close. Writes happening
  ///   outside of this transaction will not affect the stream.
  ///
  /// Starting from drift version 2.0, nested transactions are supported on most
  /// database implementations (including `NativeDatabase`, `WebDatabase`,
  /// `WasmDatabase`, `SqfliteQueryExecutor`, databases relayed through
  /// isolates or web workers).
  /// When calling [transaction] inside a [transaction] block on supported
  /// database implementations, a new transaction will be started.
  /// For backwards-compatibility, the current transaction will be re-used if
  /// a nested transaction is started with a database implementation not
  /// supporting nested transactions. The [requireNew] parameter can be set to
  /// instead turn this case into a runtime error.
  ///
  /// Nested transactions are conceptionally similar to regular, top-level
  /// transactions in the sense that their writes are not seen by users outside
  /// of the transaction until it is commited. However, their behavior around
  /// completions is different:
  ///
  /// - When a nested transaction completes, nothing is being persisted right
  ///   away. The parent transaction can now see changes from the child
  ///   transaction and continues to run. When the outermost transaction
  ///   completes, its changes (including changes from child transactions) are
  ///   written to the database.
  /// - When a nested transaction is aborted (which happens due to exceptions),
  ///   only changes in that inner transaction are reverted. The outer
  ///   transaction can continue to run if it catched the exception thrown by
  ///   the inner transaction when it aborted.
  ///
  /// See also:
  ///  - the docs on [transactions](https://drift.simonbinder.eu/docs/transactions/)
  Future<T> transaction<T>(Future<T> Function() action,
      {bool requireNew = false}) async {
    final resolved = resolvedEngine;

    // Are we about to start a nested transaction?
    if (resolved is Transaction) {
      final executor = resolved.executor as TransactionExecutor;
      if (!executor.supportsNestedTransactions) {
        if (requireNew) {
          throw UnsupportedError('The current database implementation does '
              'not support nested transactions.');
        } else {
          // Just run the block in the current transaction zone.
          return action();
        }
      }
    }

    return await resolved.doWhenOpened((executor) {
      final transactionExecutor = executor.beginTransaction();
      final transaction = Transaction(this, transactionExecutor);

      return _runConnectionZoned(transaction, () async {
        var success = false;
        try {
          final result = await action();
          success = true;
          return result;
        } catch (e, s) {
          await transactionExecutor.rollbackAfterException(e, s);

          // pass the exception on to the one who called transaction()
          rethrow;
        } finally {
          if (success) {
            try {
              await transaction.complete();
            } catch (e, s) {
              // Couldn't commit -> roll back then.
              await transactionExecutor.rollbackAfterException(e, s);
              rethrow;
            }
          }
          await transaction.disposeChildStreams();
        }
      });
    });
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

  /// Runs [calculation] in a forked [Zone] that has its [resolvedEngine] set
  /// to the [user].
  @protected
  Future<T> _runConnectionZoned<T>(
      DatabaseConnectionUser user, Future<T> Function() calculation) {
    return runZoned(calculation, zoneValues: {_zoneRootUserKey: user});
  }

  /// Will be used by generated code to resolve inline Dart components in sql.
  @protected
  GenerationContext $write(Component component,
      {bool? hasMultipleTables, int? startIndex}) {
    final context = GenerationContext.fromDb(this)
      ..explicitVariableIndex = startIndex;
    if (hasMultipleTables != null) {
      context.hasMultipleTables = hasMultipleTables;
    }
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

  /// Used by generated code to expand array variables.
  String $expandVar(int start, int amount) {
    final buffer = StringBuffer();
    final mark = executor.dialect == SqlDialect.postgres ? '@' : '?';

    for (var x = 0; x < amount; x++) {
      buffer.write('$mark${start + x}');
      if (x != amount - 1) {
        buffer.write(', ');
      }
    }

    return buffer.toString();
  }
}

extension on TransactionExecutor {
  Future<void> rollbackAfterException(
      Object exception, StackTrace trace) async {
    try {
      await rollback();
    } catch (rollBackException) {
      throw CouldNotRollBackException(exception, trace, rollBackException);
    }
  }
}
