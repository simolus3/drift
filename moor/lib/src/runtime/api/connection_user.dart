part of 'runtime_api.dart';

const _zoneRootUserKey = #DatabaseConnectionUser;

typedef _CustomWriter<T> = Future<T> Function(
    QueryExecutor e, String sql, List<dynamic> vars);

/// Manages a [DatabaseConnection] to send queries to the database.
abstract class DatabaseConnectionUser {
  /// The database connection used by this [DatabaseConnectionUser].
  @protected
  final DatabaseConnection connection;

  /// The database class that this user is attached to.
  @visibleForOverriding
  GeneratedDatabase get attachedDatabase;

  /// The type system to use with this database. The type system is responsible
  /// for mapping Dart objects into sql expressions and vice-versa.
  SqlTypeSystem get typeSystem => connection.typeSystem;

  /// The executor to use when queries are executed.
  QueryExecutor get executor => connection.executor;

  /// Manages active streams from select statements.
  @visibleForTesting
  @protected
  StreamQueryStore get streamQueries => connection.streamQueries;

  /// Constructs a database connection user, which is responsible to store query
  /// streams, wrap the underlying executor and perform type mapping.
  DatabaseConnectionUser(SqlTypeSystem typeSystem, QueryExecutor executor,
      {StreamQueryStore? streamQueries})
      : connection = DatabaseConnection(
            typeSystem, executor, streamQueries ?? StreamQueryStore());

  /// Creates another [DatabaseConnectionUser] by referencing the implementation
  /// from the [other] user.
  DatabaseConnectionUser.delegate(DatabaseConnectionUser other,
      {SqlTypeSystem? typeSystem,
      QueryExecutor? executor,
      StreamQueryStore? streamQueries})
      : connection = DatabaseConnection(
          typeSystem ?? other.connection.typeSystem,
          executor ?? other.connection.executor,
          streamQueries ?? other.connection.streamQueries,
        );

  /// Constructs a [DatabaseConnectionUser] that will use the provided
  /// [DatabaseConnection].
  DatabaseConnectionUser.fromConnection(this.connection);

  /// Creates and auto-updating stream from the given select statement. This
  /// method should not be used directly.
  Stream<T> createStream<T>(QueryStreamFetcher<T> stmt) =>
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
  T alias<T extends Table, D extends DataClass>(
      TableInfo<T, D> table, String alias) {
    return table.createAlias(alias).asDslTable;
  }

  DatabaseConnectionUser get _resolvedEngine {
    return (Zone.current[_zoneRootUserKey] as DatabaseConnectionUser?) ?? this;
  }

  /// Marks the tables as updated. This method will be called internally
  /// whenever a update, delete or insert statement is issued on the database.
  /// We can then inform all active select-streams on those tables that their
  /// snapshot might be out-of-date and needs to be fetched again.
  void markTablesUpdated(Set<TableInfo> tables) {
    notifyUpdates(
      {for (final table in tables) TableUpdate(table.actualTableName)},
    );
  }

  /// Dispatches the set of [updates] to the stream query manager.
  ///
  /// Internally, moor will call this method whenever a update, delete or insert
  /// statement is issued on the database. We can then inform all active select-
  /// streams affected that their snapshot might be out-of-date and needs to be
  /// fetched again.
  void notifyUpdates(Set<TableUpdate> updates) {
    final withRulesApplied = attachedDatabase.streamUpdateRules.apply(updates);
    _resolvedEngine.streamQueries.handleTableUpdates(withRulesApplied);
  }

  /// Creates a stream that emits `null` each time a table that would affect
  /// [query] is changed.
  ///
  /// When called inside a transaction, the stream will close when the
  /// transaction completes or is rolled back. Otherwise, the stream will
  /// complete as the database is closed.
  Stream<Null> tableUpdates(
      [TableUpdateQuery query = const TableUpdateQuery.any()]) {
    return _resolvedEngine.streamQueries
        .updatesForSync(query)
        .asyncMap((event) async {
      // streamQueries.updatesForSync is a synchronous stream - make it
      // asynchronous by awaiting null for each event.
      return await null;
    });
  }

  /// Performs the async [fn] after this executor is ready, or directly if it's
  /// already ready.
  ///
  /// Calling this method directly might circumvent the current transaction. For
  /// that reason, it should only be called inside moor.
  Future<T> doWhenOpened<T>(FutureOr<T> Function(QueryExecutor e) fn) {
    return executor.ensureOpen(attachedDatabase).then((_) => fn(executor));
  }

  /// Starts an [InsertStatement] for a given table. You can use that statement
  /// to write data into the [table] by using [InsertStatement.insert].
  InsertStatement<T, D> into<T extends Table, D extends DataClass>(
      TableInfo<T, D> table) {
    return InsertStatement<T, D>(_resolvedEngine, table);
  }

  /// Starts an [UpdateStatement] for the given table. You can use that
  /// statement to update individual rows in that table by setting a where
  /// clause on that table and then use [UpdateStatement.write].
  UpdateStatement<Tbl, R> update<Tbl extends Table, R extends DataClass>(
          TableInfo<Tbl, R> table) =>
      UpdateStatement(_resolvedEngine, table);

  /// Starts a query on the given table.
  ///
  /// In moor, queries are commonly used as a builder by chaining calls on them
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
  /// [documentation](https://moor.simonbinder.eu/docs/getting-started/writing_queries/).
  SimpleSelectStatement<T, R> select<T extends Table, R extends DataClass>(
      TableInfo<T, R> table,
      {bool distinct = false}) {
    return SimpleSelectStatement<T, R>(_resolvedEngine, table,
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
  ///  - the documentation on [aggregate expressions](https://moor.simonbinder.eu/docs/getting-started/expressions/#aggregate)
  ///  - the documentation on [group by](https://moor.simonbinder.eu/docs/advanced-features/joins/#group-by)
  JoinedSelectStatement<T, R> selectOnly<T extends Table, R extends DataClass>(
    TableInfo<T, R> table, {
    bool distinct = false,
  }) {
    return JoinedSelectStatement<T, R>(
        _resolvedEngine, table, [], distinct, false);
  }

  /// Starts a [DeleteStatement] that can be used to delete rows from a table.
  ///
  /// See the [documentation](https://moor.simonbinder.eu/docs/getting-started/writing_queries/#updates-and-deletes)
  /// for more details and example on how delete statements work.
  DeleteStatement<T, D> delete<T extends Table, D extends DataClass>(
      TableInfo<T, D> table) {
    return DeleteStatement<T, D>(_resolvedEngine, table);
  }

  /// Executes a custom delete or update statement and returns the amount of
  /// rows that have been changed.
  /// You can use the [updates] parameter so that moor knows which tables are
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
  /// You can tell moor which tables your query is going to affect by using the
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
    final engine = _resolvedEngine;

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
      Set<TableInfo> readsFrom = const {}}) {
    return CustomSelectStatement(query, variables, readsFrom, _resolvedEngine);
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
      Set<TableInfo> readsFrom = const {}}) {
    return customSelect(query, variables: variables, readsFrom: readsFrom);
  }

  /// Executes the custom sql [statement] on the database.
  Future<void> customStatement(String statement, [List<dynamic>? args]) {
    final engine = _resolvedEngine;

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
  /// Please note that nested transactions are not supported. Creating another
  /// transaction inside a transaction returns the parent transaction.
  ///
  /// See also:
  ///  - the docs on [transactions](https://moor.simonbinder.eu/docs/transactions/)
  Future<T> transaction<T>(Future<T> Function() action) async {
    final resolved = _resolvedEngine;
    if (resolved is Transaction) {
      return action();
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
        } catch (e) {
          await transactionExecutor.rollback();

          // pass the exception on to the one who called transaction()
          rethrow;
        } finally {
          if (success) {
            // complete() will also take care of committing the transaction
            await transaction.complete();
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
  Future<void> batch(Function(Batch) runInBatch) {
    final engine = _resolvedEngine;

    final batch = Batch._(engine, engine is! Transaction);
    final result = runInBatch(batch);

    if (result is Future) {
      return result.then((_) => batch._commit());
    } else {
      return batch._commit();
    }
  }

  /// Runs [calculation] in a forked [Zone] that has its [_resolvedEngine] set
  /// to the [user].
  @protected
  Future<T> _runConnectionZoned<T>(
      DatabaseConnectionUser user, Future<T> Function() calculation) {
    return runZoned(calculation, zoneValues: {_zoneRootUserKey: user});
  }

  /// Will be used by generated code to resolve inline Dart components in sql.
  @protected
  GenerationContext $write(Component component, {bool? hasMultipleTables}) {
    final context = GenerationContext.fromDb(this);
    if (hasMultipleTables != null) {
      context.hasMultipleTables = hasMultipleTables;
    }
    component.writeInto(context);

    return context;
  }
}
