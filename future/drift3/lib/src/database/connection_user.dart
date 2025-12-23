import 'dart:async';

import 'package:meta/meta.dart';

import '../connection/connection.dart';
import '../connection/interceptor.dart';
import '../connection/result_set.dart';
import '../connection/streams/scoped.dart';
import '../connection/streams/store.dart';
import '../connection/streams/update_rules.dart';
import '../exceptions.dart';
import '../query_builder/compiler.dart';
import '../query_builder/dialect.dart';
import '../query_builder/expressions/aggregate.dart';
import '../query_builder/expressions/expression.dart';
import '../query_builder/results.dart';
import '../query_builder/schema/result_set.dart';
import '../query_builder/schema/table.dart';
import '../query_builder/statements/delete.dart';
import '../query_builder/statements/insert.dart';
import '../query_builder/statements/select.dart';
import '../query_builder/statements/statement.dart';
import '../query_builder/statements/update.dart';
import 'batch.dart';
import 'custom_select.dart';
import 'data_class.dart';
import 'db_base.dart';
import 'selectable.dart';

/// The shared base class for drift databases and database accessors.
abstract base class DatabaseConnectionUser {
  /// The database class that this user is attached to.
  @visibleForOverriding
  GeneratedDatabase get attachedDatabase;

  /// The [DriftDialect] implementation for this opened database.
  DriftDialect get dialect => attachedDatabase.implementation.dialect;

  /// The current [DriftSession] that this database will use to run statements.
  Future<DriftSession> currentSession() {
    if (Zone.current[_zoneRootUserKey] case final scoped?) {
      return Future.value((scoped as _ScopedDatabaseSession)._session);
    } else {
      return attachedDatabase.rootConnection();
    }
  }

  /// Waits for the database to be initialized, meaning that all connections are
  /// fully set up and migrations ran.
  ///
  /// It is not required to call this method before using the database, drift
  /// calls it internally where necessary. However, it can be useful to
  /// explicitly await migrations.
  Future<void> initialize() async {
    await currentSession();
  }

  StreamQueryStore _currentStreamQueryStore() {
    if (Zone.current[_zoneRootUserKey] case final scoped?) {
      return (scoped as _ScopedDatabaseSession)._streamQueries;
    } else {
      return attachedDatabase.resolveRootStreamQueries();
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
  void markTablesUpdated(Iterable<GeneratedTable> tables) {
    notifyUpdates({for (final table in tables) TableUpdate.onTable(table)});
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
    _currentStreamQueryStore().handleTableUpdates(withRulesApplied);
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
  Stream<Set<TableUpdate>> tableUpdates([
    TableUpdateQuery query = const TableUpdateQuery.any(),
  ]) {
    // The stream should refer to the transaction active when tableUpdates was
    // called, not the one when a listener attaches.
    final queries = _currentStreamQueryStore();

    // We're wrapping updatesForSync in a stream controller to make it async.
    return Stream.multi((controller) {
      final source = queries.updatesForSync(query);
      source.pipe(controller);
    }, isBroadcast: true);
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
  Future<T> transaction<T>(
    Future<T> Function() action, {
    TransactionOptions? options,
  }) async {
    final resolved = await currentSession();
    final transaction = await resolved.transactionParent!.begin(
      options ?? TransactionOptions(),
    );
    final transactionControl = transaction.transaction!;
    final nestedStreams = ScopedStreamQueryStore(_currentStreamQueryStore());

    return _runConnectionZoned(
      _ScopedDatabaseSession(transaction, nestedStreams),
      () async {
        var success = false;

        try {
          final result = await action();
          success = true;
          return result;
        } catch (e, s) {
          await transactionControl.rollbackAfterException(e, s);

          // pass the exception on to the one who called transaction()
          rethrow;
        } finally {
          if (success) {
            try {
              await transactionControl.commit();
            } catch (e, s) {
              // Couldn't commit -> roll back then.
              await transactionControl.rollbackAfterException(e, s);
              rethrow;
            }
          }

          await nestedStreams.close(forwardUpdates: success);
        }
      },
    );
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
  Future<BatchResult> batch(
    FutureOr<void> Function(Batch batch) runInBatch,
  ) async {
    final batch = createBatch(this);
    await Future(() => runInBatch(batch));

    return await runBatch(batch);
  }

  /// Executes [action] with calls intercepted by the given [interceptor]
  ///
  /// This can be used to, for instance, write a custom statement logger or to
  /// retry failing statements automatically.
  Future<T> runWithInterceptor<T>(
    Future<T> Function() action, {
    required QueryInterceptor interceptor,
  }) async {
    final session = await currentSession();

    return _runConnectionZoned(
      _ScopedDatabaseSession(
        session.interceptWith(interceptor),
        currentStreamQueryStore(),
      ),
      action,
    );
  }

  /// Obtains an exclusive lock on the current database context, runs [action]
  /// in it and then releases the lock.
  ///
  /// This obtains a local lock on the underlying [currentSession] without
  /// starting a transaction or coordinating with other processes on the same
  /// database.
  /// It is possible to start a [transaction] within an [exclusively] block.
  /// When [exclusively] is called on a database connected to a remote isolate
  /// or a shared web worker, other isolates and tabs will be blocked on the
  /// database until the returned future completes.
  ///
  /// With sqlite3, [exclusively] is useful to set certain pragmas like
  /// `foreign_keys` which can't be done in a transaction for a limited scope.
  /// For instance, some migrations may look like this:
  ///
  /// ```dart
  /// await exclusively(() async {
  ///   await customStatement('pragma foreign_keys = OFF;');
  ///   await transaction(() async {
  ///     // complex updates or migrations temporarily breaking foreign
  ///     // references...
  ///   });
  ///   await customStatement('pragma foreign_keys = OFF;');
  /// });
  /// ```
  ///
  /// If the [exclusively] block had been omitted from the previous snippet,
  /// it would have been possible for other concurrent database calls to occur
  /// between the transaction and the `pragma` statements.
  ///
  /// Outside of blocks requiring exclusive access to set pragmas not supported
  /// in transactions, consider using [transaction] instead of [exclusively].
  /// Transactions also take exclusive control over the database, but they also
  /// are atomic (either all statements in a transaction complete or none at
  /// all), whereas an error in an [exclusively] block does not roll back
  /// earlier statements.
  Future<T> exclusively<T>(Future<T> Function() action) async {
    final resolved = await currentSession();
    final exclusive = await resolved.locks!.exclusive();
    final streams = ScopedStreamQueryStore(_currentStreamQueryStore());

    return _runConnectionZoned(
      _ScopedDatabaseSession(exclusive, streams),
      () async {
        try {
          return await action();
        } finally {
          await exclusive.close();
          await streams.close();
        }
      },
    );
  }

  /// Runs [calculation] in a forked [Zone] that has its [currentSession] set
  /// to the [session].
  @protected
  Future<T> _runConnectionZoned<T>(
    _ScopedDatabaseSession session,
    Future<T> Function() calculation,
  ) {
    return runZoned(calculation, zoneValues: {_zoneRootUserKey: session});
  }

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
  RS alias<Row extends Object, RS extends ResultSet<Row, RS>>(
    ResultSet<Row, RS> table,
    String alias,
  ) {
    return table.withAlias(alias).asSelfType();
  }

  /// Starts a query on the given table.
  ///
  /// In drift, queries are commonly used as a builder by chaining calls on
  /// them. For instance, to load the 10 oldest users
  /// with an 'S' in their name, you could use:
  /// ```dart
  /// Future<List<User>> oldestUsers() {
  ///   return select(users)
  ///     .where((u) => u.name.like('%S%'))
  ///     .orderBy([(u) => OrderingTerm(
  ///         expression: u.id,
  ///         mode: OrderingMode.asc
  ///      )])
  ///     .limit(10)
  ///     .get();
  /// }
  /// ```
  ///
  /// The [distinct] parameter (defaults to false) can be used to remove
  /// duplicate rows from the result set.
  ///
  /// For more information on queries, see the
  /// [documentation](https://drift.simonbinder.eu/docs/getting-started/writing_queries/).
  SingleTableSelectStatement<Row, RS> select<
    Row extends Object,
    RS extends ResultSet<Row, RS>
  >(ResultSet<Row, RS> table, {bool distinct = false}) {
    return SingleTableSelectStatement<Row, RS>(this, table, distinct: distinct);
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
  ///   final query = selectOnly(comments)
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
  SelectStatement selectOnly(ResultSet table, {bool distinct = false}) {
    final statement = SelectStatement(
      this,
      includeJoinsByDefault: false,
      distinct: distinct,
    );
    statement.from.add(FromResultSet(table));
    return statement;
  }

  /// Counts the amount of rows in a table.
  ///
  /// The optional [where] clause can be used to only count rows matching the
  /// condition, similar to [SingleTableSelectStatement.where].
  ///
  /// The returned [Selectable] can be run once with [Selectable.getSingle] to
  /// get the count once, or be watched as a stream with [Selectable.watchSingle].
  SingleSelectable<int> count<
    Row extends Object,
    RS extends ResultSet<Row, RS>
  >(ResultSet<Row, RS> table, {Expression<bool> Function(RS row)? where}) {
    final count = countAll();
    final stmt = selectOnly(table).addColumns([count]);
    if (where != null) {
      stmt.where(where(table.asSelfType()));
    }

    return stmt.map((row) => row.read(count)!);
  }

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
  SelectStatement selectExpressions(Iterable<Expression> columns) {
    return SelectStatement(this)..addColumns(columns);
  }

  /// Starts an [InsertStatement] for a given table. You can use that statement
  /// to write data into the [table] by using [InsertStatement.insert].
  InsertStatement<Row, RS, DatabaseConnectionUser> into<
    Row extends Object,
    RS extends GeneratedTable<Row, RS>
  >(GeneratedTable<Row, RS> table) {
    return InsertStatement<Row, RS, DatabaseConnectionUser>(this, table);
  }

  /// Starts an [UpdateStatement] for the given table. You can use that
  /// statement to update individual rows in that table by setting a where
  /// clause on that table and then use [UpdateStatement.write].
  UpdateStatement<Row, RS> update<
    Row extends Object,
    RS extends GeneratedTable<Row, RS>
  >(GeneratedTable<Row, RS> table) {
    return UpdateStatement<Row, RS>(this, table);
  }

  /// Starts a [DeleteStatement] that can be used to delete rows from a table.
  ///
  /// See the [documentation](https://drift.simonbinder.eu/docs/dart-api/writes/#updates-and-deletes)
  /// for more details and example on how delete statements work.
  DeleteStatement<Row, RS> delete<
    Row extends Object,
    RS extends GeneratedTable<Row, RS>
  >(GeneratedTable<Row, RS> table) {
    return DeleteStatement<Row, RS>(this, table);
  }

  /// Runs the compiled [SqlStatement] on the [currentSession].
  Future<QueryResult> runStatement(SqlStatement statement) async {
    final info = dialect.compile(statement);
    return (await currentSession()).execute(info);
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
  Selectable<CustomRow> customSelect(
    String query, {
    List<MappedValue> variables = const [],
    Set<ResultSet> readsFrom = const {},
    bool isReadOnly = true,
  }) {
    return CustomSelectStatement.unmapped(
      query,
      variables,
      readsFrom,
      this,
      isReadOnly,
    );
  }

  /// A variant of [customSelect] that uses [createMapper] to obtain a select
  /// statement for which rows can be mapped to a custom Dart type.
  Selectable<T> customSelectMapped<T>({
    required String query,
    required T Function(DriftRow) Function(DriftResultSet) createMapper,
    List<MappedValue> variables = const [],
    Set<ResultSet> readsFrom = const {},
    bool isReadOnly = true,
  }) {
    return CustomSelectStatement(
      query,
      variables,
      readsFrom,
      createMapper,
      this,
      isReadOnly,
    );
  }

  /// Executes the custom sql [statement] on the database.
  ///
  /// [statement] should contain exactly one SQL statement. Attempting to run
  /// multiple statements with a single [customStatement] may not be fully
  /// supported on all platforms.
  Future<void> customStatement(
    String statement, [
    List<MappedValue> args = const [],
  ]) async {
    final session = await currentSession();
    await session.execute(StatementInfo(statement, variables: args));
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
    List<MappedValue> variables = const [],
    Set<ResultSet>? updates,
    UpdateKind? updateKind,
  }) async {
    final result = await _customWrite(
      query,
      variables,
      updates,
      UpdateKind.update,
      false,
    );
    return result.affectedRows ?? 0;
  }

  /// Executes a custom insert statement and returns the last inserted rowid.
  ///
  /// You can tell drift which tables your query is going to affect by using the
  /// [updates] parameter. Query-streams running on any of these tables will
  /// then be re-run.
  Future<int> customInsert(
    String query, {
    List<MappedValue> variables = const [],
    Set<ResultSet>? updates,
  }) async {
    final result = await _customWrite(
      query,
      variables,
      updates,
      UpdateKind.insert,
      false,
    );
    return result.lastInsertRowId ?? 0;
  }

  /// Runs a `INSERT`, `UPDATE` or `DELETE` statement returning rows.
  ///
  /// You can use the [updates] parameter so that drift knows which tables are
  /// affected by your query. All select streams that depend on a table
  /// specified there will then update their data. For more accurate results,
  /// you can also set the [updateKind] parameter.
  /// This is optional, but can improve the accuracy of query updates,
  /// especially when using triggers.
  Future<DriftResultSet> customWriteReturning(
    String query, {
    List<MappedValue> variables = const [],
    Set<ResultSet>? updates,
    UpdateKind? updateKind,
  }) async {
    final result = await _customWrite(
      query,
      variables,
      updates,
      updateKind,
      true,
    );
    return DriftResultSet(ResultSetStructure(), result.resultSet!, dialect);
  }

  /// Common logic for [customUpdate] and [customInsert] which takes care of
  /// mapping the variables, running the query and optionally informing the
  /// stream-queries.
  Future<QueryResult> _customWrite(
    String query,
    List<MappedValue> variables,
    Set<ResultSet>? updates,
    UpdateKind? updateKind,
    bool needsResultSet,
  ) async {
    final session = await currentSession();
    final result = await session.execute(
      StatementInfo(
        query,
        variables: variables,
        needsResultSet: needsResultSet,
      ),
    );

    if (updates != null) {
      notifyUpdates({
        for (final table in updates)
          TableUpdate(table.entityName, kind: updateKind),
      });
    }

    return result;
  }

  /// Used by generated code to expand array variables.
  String $expandVar(int start, int amount) {
    final compiler = dialect.createCompiler();

    for (var x = 0; x < amount; x++) {
      compiler.addPositionalVariable(start + x);

      if (x != amount - 1) {
        compiler.statement.comma();
      }
    }

    return compiler.statement.buffer.toString();
  }

  /// Will be used by generated code to resolve inline Dart components in sql by
  /// writing the [component].
  @protected
  StatementBuffer $write(
    SqlComponent component, {
    bool? hasMultipleTables,
    int? startIndex,
  }) {
    final compiler = dialect.createCompiler();
    compiler.statement
      ..variableOffset = startIndex ?? 0
      ..hasMultipleTables = hasMultipleTables ?? false;

    component.compileWith(compiler);
    return compiler.statement;
  }

  /// Writes column names and `VALUES` for an insert statement.
  ///
  /// Used by generated code.
  @protected
  StatementBuffer $writeInsertable(
    GeneratedTable table,
    Insertable insertable, {
    int? startIndex,
  }) {
    /*
    final context = GenerationContext.fromDb(this)
      ..explicitVariableIndex = startIndex;

    table.validateIntegrity(insertable, isInserting: true);
    InsertStatement(this, table)
        .writeInsertable(context, insertable.toColumns(true));

    return context;*/
    throw 'todo';
  }
}

final class _ScopedDatabaseSession {
  final DriftSession _session;
  final StreamQueryStore _streamQueries;

  _ScopedDatabaseSession(this._session, this._streamQueries);
}

extension on DriftTransactionSession {
  Future<void> rollbackAfterException(
    Object exception,
    StackTrace trace,
  ) async {
    try {
      await rollback();
    } catch (rollBackException) {
      throw CouldNotRollBackException(exception, trace, rollBackException);
    }
  }
}

/// Methods available internally but not exposed as part of drift's public API.
@internal
extension InternalConnectionUser on DatabaseConnectionUser {
  Object get _zoneRootUserKey => (#DatabaseConnectionUser, attachedDatabase);

  Future<T> runConnectionZoned<T>(
    DriftSession session,
    StreamQueryStore streamQueries,
    Future<T> Function() calculation,
  ) {
    final wrapped = _ScopedDatabaseSession(session, streamQueries);
    return runZoned(calculation, zoneValues: {_zoneRootUserKey: wrapped});
  }

  StreamQueryStore currentStreamQueryStore() => _currentStreamQueryStore();
}
