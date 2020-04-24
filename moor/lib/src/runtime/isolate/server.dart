part of 'moor_isolate.dart';

class _MoorServer {
  final Server server;

  DatabaseConnection connection;

  final Map<int, QueryExecutor> _managedExecutors = {};
  int _currentExecutorId = 0;

  /// when a transaction is active, all queries that don't operate on another
  /// query executor have to wait!
  ///
  /// When this list is empty, the top-level executor is active. When not, the
  /// first transaction id in the backlog is active at the moment. Whenever a
  /// transaction completes, we emit an item on [_backlogUpdated]. This can be
  /// used to implement a lock.
  final List<int> _executorBacklog = [];
  final StreamController<void> _backlogUpdated =
      StreamController.broadcast(sync: true);

  _IsolateDelegatedUser _dbUser;

  SendPort get portToOpenConnection => server.portToOpenConnection;

  _MoorServer(DatabaseOpener opener) : server = Server(const _MoorCodec()) {
    server.openedConnections.listen((connection) {
      connection.setRequestHandler(_handleRequest);
    });
    connection = opener();
    _dbUser = _IsolateDelegatedUser(this);
  }

  /// Returns the first connected client, or null if no client is connected.
  IsolateCommunication get firstClient {
    final channels = server.currentChannels;
    return channels.isEmpty ? null : channels.first;
  }

  dynamic _handleRequest(Request r) {
    final payload = r.payload;

    if (payload is _NoArgsRequest) {
      switch (payload) {
        case _NoArgsRequest.getTypeSystem:
          return connection.typeSystem;
        case _NoArgsRequest.startTransaction:
          return _spawnTransaction();
        case _NoArgsRequest.terminateAll:
          _backlogUpdated.close();
          connection.executor.close();
          server.close();
          Isolate.current.kill();
          break;
      }
    } else if (payload is _EnsureOpen) {
      return _handleEnsureOpen(payload);
    } else if (payload is _ExecuteQuery) {
      return _runQuery(
          payload.method, payload.sql, payload.args, payload.executorId);
    } else if (payload is _ExecuteBatchedStatement) {
      return _runBatched(payload.stmts, payload.executorId);
    } else if (payload is _NotifyTablesUpdated) {
      for (final connected in server.currentChannels) {
        connected.request(payload);
      }
    } else if (payload is _RunTransactionAction) {
      return _transactionControl(payload.control, payload.transactionId);
    }
  }

  Future<bool> _handleEnsureOpen(_EnsureOpen open) async {
    _dbUser.schemaVersion = open.schemaVersion;
    final executor = await _loadExecutor(open.executorId);

    return await executor.ensureOpen(_dbUser);
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

  Future<void> _runBatched(BatchedStatements stmts, int transactionId) async {
    final executor = await _loadExecutor(transactionId);
    await executor.runBatched(stmts);
  }

  Future<QueryExecutor> _loadExecutor(int transactionId) async {
    await _waitForTurn(transactionId);
    return transactionId != null
        ? _managedExecutors[transactionId]
        : connection.executor;
  }

  Future<int> _spawnTransaction() async {
    final transaction = connection.executor.beginTransaction();
    final id = _putExecutor(transaction);

    await transaction.ensureOpen(_dbUser);
    return id;
  }

  int _putExecutor(QueryExecutor executor) {
    final id = _currentExecutorId++;
    _managedExecutors[id] = executor;
    _executorBacklog.add(id);
    return id;
  }

  Future<void> _transactionControl(
      _TransactionControl action, int transactionId) async {
    final executor = _managedExecutors[transactionId];
    if (executor is! TransactionExecutor) {
      throw ArgumentError.value(
          transactionId, 'transactionId', 'Does not reference a transaction');
    }

    final transaction = executor as TransactionExecutor;

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
      _releaseExecutor(transactionId);
    }
  }

  void _releaseExecutor(int id) {
    _managedExecutors.remove(id);
    _executorBacklog.remove(id);
    _notifyActiveExecutorUpdated();
  }

  Future<void> _waitForTurn(int transactionId) {
    bool idIsActive() {
      if (transactionId == null) {
        return _executorBacklog.isEmpty;
      } else {
        return _executorBacklog.isNotEmpty &&
            _executorBacklog.first == transactionId;
      }
    }

    // Don't wait for a backlog update if the current transaction id is active
    if (idIsActive()) return Future.value(null);

    return _backlogUpdated.stream.firstWhere((_) => idIsActive());
  }

  void _notifyActiveExecutorUpdated() {
    if (!_backlogUpdated.isClosed) {
      _backlogUpdated.add(null);
    }
  }
}

class _IsolateDelegatedUser implements QueryExecutorUser {
  final _MoorServer server;

  @override
  int schemaVersion = 0;

  _IsolateDelegatedUser(this.server); // will be overridden by client requests

  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {
    final id = server._putExecutor(executor);
    try {
      await server.firstClient.request(_RunBeforeOpen(details, id));
    } finally {
      server._releaseExecutor(id);
    }
  }
}
