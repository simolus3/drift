part of 'moor_isolate.dart';

class _MoorServer {
  final Server server;

  DatabaseConnection connection;

  final Map<int, TransactionExecutor> _transactions = {};
  int _currentTransaction = 0;

  /// when a transaction is active, all queries that don't operate on another
  /// query executor have to wait!
  ///
  /// When this list is empty, the top-level executor is active. When not, the
  /// first transaction id in the backlog is active at the moment. Whenever a
  /// transaction completes, we emit an item on [_backlogUpdated]. This can be
  /// used to implement a lock.
  final List<int> _transactionBacklog = [];
  final StreamController<void> _backlogUpdated =
      StreamController.broadcast(sync: true);

  _FakeDatabase _fakeDb;

  ServerKey get key => server.key;

  _MoorServer(DatabaseOpener opener) : server = Server() {
    server.openedConnections.listen((connection) {
      connection.setRequestHandler((r) => _handleRequest(connection, r));
    });
    connection = opener();

    _fakeDb = _FakeDatabase(connection, this);
    connection.executor.databaseInfo = _fakeDb;
  }

  /// The executor running the special beforeOpen callback, if that callback
  /// is currently running. Otherwise null.
  QueryExecutor _beforeOpenExecutor;

  /// The client currently running the beforeOpen callback, or null if that
  /// callback is not currently active.
  IsolateCommunication _beforeOpenClient;

  /// Returns the first connected client, or null if no client is connected.
  IsolateCommunication get firstClient {
    final channels = server.currentChannels;
    return channels.isEmpty ? null : channels.first;
  }

  dynamic _handleRequest(IsolateCommunication channel, Request r) {
    final payload = r.payload;

    if (payload is _NoArgsRequest) {
      switch (payload) {
        case _NoArgsRequest.getTypeSystem:
          return connection.typeSystem;
        case _NoArgsRequest.ensureOpen:
          return _runEnsureOpen(channel);
        case _NoArgsRequest.startTransaction:
          return _spawnTransaction();
        case _NoArgsRequest.terminateAll:
          _backlogUpdated.close();
          connection.executor.close();
          server.close();
          Isolate.current.kill();
          break;
        // the following are requests which are handled on the client side
        case _NoArgsRequest.runOnCreate:
          throw UnsupportedError(
              'This operation needs to be run on the client');
      }
    } else if (payload is _SetSchemaVersion) {
      _fakeDb.schemaVersion = payload.schemaVersion;
      return null;
    } else if (payload is _ExecuteQuery) {
      return _runQuery(
          payload.method, payload.sql, payload.args, payload.transactionId);
    } else if (payload is _ExecuteBatchedStatement) {
      return _runBatched(payload.stmts, payload.transactionId);
    } else if (payload is _NotifyTablesUpdated) {
      for (final connected in server.currentChannels) {
        connected.request(payload);
      }
    } else if (payload is _RunTransactionAction) {
      return _transactionControl(payload.control, payload.transactionId);
    }
  }

  Future<bool> _runEnsureOpen(IsolateCommunication requestingChannel) {
    if (requestingChannel == _beforeOpenClient) {
      return _beforeOpenExecutor.ensureOpen();
    } else {
      return connection.executor.ensureOpen();
    }
  }

  Future<dynamic> _runQuery(
      _StatementMethod method, String sql, List args, int transactionId) async {
    final executor = await _loadExecutor(transactionId);

    switch (method) {
      case _StatementMethod.custom:
        return executor.runCustom(sql, args);
      case _StatementMethod.deleteOrUpdate:
        return executor.runDelete(sql, args);
      case _StatementMethod.insert:
        return executor.runInsert(sql, args);
      case _StatementMethod.select:
        return executor.runSelect(sql, args);
    }

    throw AssertionError("Unknown _StatementMethod, this can't happen.");
  }

  Future<void> _runBatched(
      List<BatchedStatement> stmts, int transactionId) async {
    final executor = await _loadExecutor(transactionId);
    await executor.runBatched(stmts);
  }

  Future<QueryExecutor> _loadExecutor(int transactionId) async {
    await _waitForTurn(transactionId);
    return transactionId != null
        ? _transactions[transactionId]
        : connection.executor;
  }

  Future<int> _spawnTransaction() async {
    final id = _currentTransaction++;
    final transaction = connection.executor.beginTransaction();

    _transactions[id] = transaction;
    _transactionBacklog.add(id);
    await transaction.ensureOpen();
    return id;
  }

  Future<void> _transactionControl(
      _TransactionControl action, int transactionId) async {
    final transaction = _transactions[transactionId];

    try {
      switch (action) {
        case _TransactionControl.commit:
          await transaction.send();
          break;
        case _TransactionControl.rollback:
          await transaction.rollback();
          break;
      }
    } finally {
      _transactions.remove(transactionId);
      _transactionBacklog.remove(transactionId);
      _notifyTransactionsUpdated();
    }
  }

  Future<void> _waitForTurn(int transactionId) {
    bool idIsActive() {
      if (transactionId == null) {
        return _transactionBacklog.isEmpty;
      } else {
        return _transactionBacklog.isNotEmpty &&
            _transactionBacklog.first == transactionId;
      }
    }

    // Don't wait for a backlog update if the current transaction id is active
    if (idIsActive()) return Future.value(null);

    return _backlogUpdated.stream.firstWhere((_) => idIsActive());
  }

  void _notifyTransactionsUpdated() {
    if (!_backlogUpdated.isClosed) {
      _backlogUpdated.add(null);
    }
  }
}

/// A mock database so that the [QueryExecutor] which is running on a background
/// isolate can have the [QueryExecutor.databaseInfo] set. The query executor
/// uses that to set the schema version and to run migration callbacks. For a
/// server, all of that is delegated via clients.
class _FakeDatabase extends GeneratedDatabase {
  final _MoorServer server;

  _FakeDatabase(DatabaseConnection connection, this.server)
      : super.connect(connection);

  @override
  final List<TableInfo<Table, DataClass>> allTables = const [];

  @override
  int schemaVersion = 0; // will be overridden by client requests

  @override
  Future<void> handleDatabaseCreation({SqlExecutor executor}) {
    return server.firstClient.request(_NoArgsRequest.runOnCreate);
  }

  @override
  Future<void> handleDatabaseVersionChange(
      {SqlExecutor executor, int from, int to}) {
    return server.firstClient.request(_RunOnUpgrade(from, to));
  }

  @override
  Future<void> beforeOpenCallback(
      QueryExecutor executor, OpeningDetails details) async {
    final client = server._beforeOpenClient = server.firstClient;
    server._beforeOpenExecutor = executor;

    try {
      await client.request(_RunBeforeOpen(details));
    } finally {
      server._beforeOpenExecutor = null;
      server._beforeOpenClient = null;
    }
  }
}
