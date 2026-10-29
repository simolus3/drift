import 'dart:async';

import 'package:drift3_preview/drift.dart' hide ResultSet;
import 'package:meta/meta.dart';
import 'package:sqlite3_connection_pool/sqlite3_connection_pool.dart';
import 'package:sqlite3/sqlite3.dart';

import 'pool/worker.dart';
import 'shared.dart';

/// A [DriftSession] implemented over a native connection pool.
@internal
final class SqlitePoolSession
    implements
        DriftSession,
        DriftTransactionParent,
        DriftSessionWithInternalLocks {
  final SqliteConnectionPool pool;
  final DatabaseWorkers? isolates;

  var _outstandingLeases = 0;
  final Completer<void> _closing = Completer();
  final Completer<void> _lastLeaseCompleted = Completer();

  final bool includePersistentSchemaVersion;

  SqlitePoolSession(
    this.pool, {
    this.isolates,
    this.includePersistentSchemaVersion = true,
  });

  @override
  Future<void> close() {
    if (!isClosed) {
      _closing.complete(_closeInternal());
    }

    return closed;
  }

  @override
  Future<void> get closed => _closing.future;

  @override
  bool get isClosed => _closing.isCompleted;

  Future<void> _closeInternal() async {
    await pool.close(abortOutstandingRequests: true);

    if (_outstandingLeases > 0) {
      await _lastLeaseCompleted.future;
    } else {
      // We have aborted outstanding requests, so _outstandingLeases won't be
      // incremented by concurrent requests either. We're done using the pool.
      _lastLeaseCompleted.complete();
    }

    // We have awaited all outstanding leases, so all isolates must be idle at
    // this point. Close them.
    await isolates?.close();
  }

  void _markLeaseReturned() {
    _outstandingLeases--;
    assert(_outstandingLeases >= 0);

    if (_outstandingLeases == 0 && isClosed) {
      _lastLeaseCompleted.complete();
    }
  }

  Future<(T, DatabaseWorker?)> _waitForConnection<T extends Object>(
    Future<T> acquire,
    void Function(T) release,
  ) async {
    if (isClosed) {
      throw StateError('Session has been closed');
    }

    _outstandingLeases++;
    DatabaseWorker? isolate;
    T? acquired;

    try {
      acquired = await acquire.poolAbortExceptionsToDrift();
      isolate = await isolates?.acquireWorker();
      return (acquired, isolate);
    } on Object {
      if (acquired != null) release(acquired);
      if (isolate != null) isolates!.returnIsolateWorker(isolate);
      _markLeaseReturned();
      _markLeaseReturned();
      rethrow;
    }
  }

  Future<_PlainLease> _lease(bool writer) async {
    final (connection, isolate) = await _waitForConnection(
      writer
          ? pool.writer(abortSignal: cancellationSignal)
          : pool.reader(abortSignal: cancellationSignal),
      (lease) => lease.returnLease(),
    );

    return _PlainLease(connection, this, connection, isolate);
  }

  @override
  Future<QueryResult> execute(StatementInfo statement) async {
    final connection = await _lease(!statement.isReadOnly);
    try {
      return await connection.execute(statement);
    } finally {
      connection._closeDirectly();
    }
  }

  @override
  Future<List<QueryResult>> executeBatch(StatementBatch batch) async {
    final writer = await _lease(true);
    try {
      return await writer.executeBatch(batch);
    } finally {
      writer._closeDirectly();
    }
  }

  @override
  DriftSessionWithInternalLocks? get locks => this;

  @override
  PersistentSchemaVersion? get persistentSchemaVersion {
    return includePersistentSchemaVersion
        ? PragmaPersistedSchemaVersion(this)
        : null;
  }

  @override
  Object? get tag => this;

  @override
  // The root pool itself is never in a transaction, we'd hand out connection
  // leases to implement those.
  DriftTransactionSession? get transaction => null;

  @override
  DriftTransactionParent? get transactionParent => this;

  @override
  Future<DriftSession> begin(TransactionOptions options) async {
    final connection = await _lease(!options.readOnly);
    return await connection.beginTransaction();
  }

  @override
  Future<DriftSession> exclusive() async {
    final (access, isolate) = await _waitForConnection(
      pool.exclusiveAccess(abortSignal: cancellationSignal),
      (access) => access.close(),
    );

    return _ExclusivePoolConnection(this, access, isolate);
  }
}

/// A [StreamQueryStore] implemented on a [SqliteConnectionPool].
final class SqlitePoolUpdates extends StreamQueryStore {
  final SqliteConnectionPool _pool;
  final bool _enableCustomUpdates;

  /// @nodoc
  SqlitePoolUpdates(this._pool, {required bool enableCustomUpdates})
    : _enableCustomUpdates = enableCustomUpdates;

  @override
  void handleTableUpdates(Set<TableUpdate> updates) {
    if (_enableCustomUpdates) {
      _pool.dispatchUpdateNotification([
        for (final update in updates) update.table,
      ]);
    }
  }

  @override
  Stream<Set<TableUpdate>> updatesForSync(TableUpdateQuery query) {
    return _pool.updatedTables
        .map((tables) {
          return {for (final table in tables) TableUpdate(table)};
        })
        .where((updates) => updates.any(query.matches));
  }
}

abstract class _LeasedPoolConnection implements DriftSession {
  final Completer<void> _closed = Completer();
  final DatabaseWorker? _worker;
  final SqlitePoolSession _root;
  final AsyncConnection _connection;

  _LeasedPoolConnection(this._root, this._connection, this._worker);

  void _returnConnection();

  @override
  Future<void> close() async {
    if (!isClosed) {
      _closeDirectly();
    }
  }

  void _closeDirectly() {
    _returnConnection();
    if (_worker case final worker?) {
      _root.isolates!.returnIsolateWorker(worker);
    }
    _root._markLeaseReturned();
    _closed.complete();
  }

  Future<T> _runWithDatabase<T>(T Function(PoolConnection) closure) {
    // This is safe because the closure doesn't close the database.
    return _connection.unsafeAccess((connection) {
      if (_worker case final worker?) {
        return worker.execute(connection, closure);
      } else {
        return closure(connection);
      }
    });
  }

  @override
  Future<void> get closed => _closed.future;

  @override
  bool get isClosed => _closed.isCompleted;

  @override
  Future<QueryResult> execute(StatementInfo statement) {
    return _runWithDatabase(
      _PoolConnectionStatements._runClosure(
        statement.sql,
        statement.variables,
        statement.needsResultSet,
      ),
    );
  }

  @override
  Future<List<QueryResult>> executeBatch(StatementBatch batch) {
    return _runWithDatabase(_PoolConnectionStatements._runBatchClosure(batch));
  }

  @override
  DriftSessionWithInternalLocks? get locks => null;

  @override
  PersistentSchemaVersion? get persistentSchemaVersion => null;

  @override
  Object? get tag => null;

  @override
  DriftTransactionSession? get transaction => null;

  @override
  DriftTransactionParent? get transactionParent => null;
}

final class _PlainLease extends _LeasedPoolConnection {
  final ConnectionLease _lease;

  _PlainLease(this._lease, super.root, super.connection, super.worker);

  @override
  void _returnConnection() {
    _lease.returnLease();
  }

  Future<_TransactionPoolConnection> beginTransaction() async {
    try {
      assert(await _connection.autocommit);
      await _runWithDatabase(
        _PoolConnectionStatements._executeClosure('BEGIN IMMEDIATE'),
      );
      assert(!await _connection.autocommit);
    } on Object {
      _closeDirectly();
      rethrow;
    }

    return _TransactionPoolConnection(_root, _lease, _worker);
  }
}

final class _TransactionPoolConnection extends _LeasedPoolConnection
    implements DriftTransactionSession {
  final ConnectionLease _lease;

  _TransactionPoolConnection(
    SqlitePoolSession session,
    this._lease,
    DatabaseWorker? _worker,
  ) : super(session, _lease, _worker);

  @override
  DriftTransactionSession? get transaction => this;

  @override
  void _returnConnection() {
    _lease.returnLease();
  }

  @override
  Future<void> commit() async {
    await _runWithDatabase(_PoolConnectionStatements._executeClosure('COMMIT'));
    await close();
  }

  @override
  Future<void> rollback() async {
    await _runWithDatabase(
      _PoolConnectionStatements._executeClosure('ROLLBACK'),
    );
    await close();
  }
}

final class _ExclusivePoolConnection extends _LeasedPoolConnection {
  final ExclusivePoolAccess _access;

  _ExclusivePoolConnection(
    SqlitePoolSession session,
    this._access,
    DatabaseWorker? _worker,
  ) : super(session, _access.writer, _worker);

  @override
  void _returnConnection() {
    _access.close();
  }
}

extension _PoolConnectionStatements on PoolConnection {
  QueryResult run(String sql, List<Object?> variables, bool needsResult) {
    final rawDb = database;
    RawResultSet? resultSet;

    if (needsResult) {
      resultSet = SqliteResultSet(resultSet: select(sql, variables));
    } else {
      execute(sql, variables);
    }

    return QueryResult(
      resultSet: resultSet,
      affectedRows: rawDb.updatedRows,
      lastInsertRowId: rawDb.lastInsertRowId,
    );
  }

  List<QueryResult> runBatch(StatementBatch batch) {
    final database = this.database;
    final results = <QueryResult>[];
    final prepared = <PreparedStatement>[];

    try {
      for (final sql in batch.sql) {
        prepared.add(database.prepare(sql));
      }

      for (final stmt in batch.statements) {
        results.add(
          executeWithStatement(database, prepared[stmt.sqlIndex], stmt.info),
        );
      }
    } finally {
      for (final stmt in prepared) {
        stmt.close();
      }
    }

    return results;
  }

  static QueryResult Function(PoolConnection) _runClosure(
    String sql,
    List<Object?> variables,
    bool needsResult,
  ) {
    return (conn) => conn.run(sql, variables, needsResult);
  }

  static List<QueryResult> Function(PoolConnection) _runBatchClosure(
    StatementBatch batch,
  ) {
    return (conn) => conn.runBatch(batch);
  }

  static void Function(PoolConnection) _executeClosure(String sql) {
    return (conn) => conn.execute(sql);
  }
}

extension<T> on Future<T> {
  Future<T> poolAbortExceptionsToDrift() {
    return onError<PoolAbortException>(
      (_, _) => throw const CancellationException(),
    );
  }
}
