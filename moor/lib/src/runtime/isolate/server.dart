part of 'moor_isolate.dart';

class _MoorServer {
  final Server server;

  final DatabaseConnection connection;

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

  late final _IsolateDelegatedUser _dbUser = _IsolateDelegatedUser(this);

  SendPort get portToOpenConnection => server.portToOpenConnection;

  _MoorServer(DatabaseOpener opener)
      : connection = opener(),
        server = Server(const _MoorCodec()) {
    server.openedConnections.listen((connection) {
      connection.setRequestHandler(_handleRequest);
    });
  }

  /// Returns the first connected client, or null if no client is connected.
  IsolateCommunication? get firstClient {
    final channels = server.currentChannels;
    return channels.isEmpty ? null : channels.first;
  }

  dynamic _handleRequest(Request request) {
    final payload = request.payload;

    if (payload is _NoArgsRequest) {
      switch (payload) {
        case _NoArgsRequest.getTypeSystem:
          return connection.typeSystem;
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
      return _transactionControl(payload.control, payload.executorId);
    }
  }

  Future<bool> _handleEnsureOpen(_EnsureOpen open) async {
    _dbUser.schemaVersion = open.schemaVersion;
    final executor = await _loadExecutor(open.executorId);

    return await executor.ensureOpen(_dbUser);
  }

  Future<dynamic> _runQuery(_StatementMethod method, String sql, List args,
      int? transactionId) async {
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
  }

  Future<void> _runBatched(BatchedStatements stmts, int? transactionId) async {
    final executor = await _loadExecutor(transactionId);
    await executor.runBatched(stmts);
  }

  Future<QueryExecutor> _loadExecutor(int? transactionId) async {
    await _waitForTurn(transactionId);
    return transactionId != null
        ? _managedExecutors[transactionId]!
        : connection.executor;
  }

  Future<int> _spawnTransaction(int? executor) async {
    final transaction = (await _loadExecutor(executor)).beginTransaction();
    final id = _putExecutor(transaction, beforeCurrent: true);

    await transaction.ensureOpen(_dbUser);
    return id;
  }

  int _putExecutor(QueryExecutor executor, {bool beforeCurrent = false}) {
    final id = _currentExecutorId++;
    _managedExecutors[id] = executor;

    if (beforeCurrent && _executorBacklog.isNotEmpty) {
      _executorBacklog.insert(0, id);
    } else {
      _executorBacklog.add(id);
    }

    return id;
  }

  Future<dynamic> _transactionControl(
      _TransactionControl action, int? executorId) async {
    if (action == _TransactionControl.begin) {
      return await _spawnTransaction(executorId);
    }

    final executor = _managedExecutors[executorId];
    if (executor is! TransactionExecutor) {
      throw ArgumentError.value(
        executorId,
        'transactionId',
        "Does not reference a transaction. This might happen if you don't "
            'await all operations made inside a transaction, in which case the '
            'transaction might complete with pending operations.',
      );
    }

    try {
      switch (action) {
        case _TransactionControl.commit:
          await executor.send();
          break;
        case _TransactionControl.rollback:
          await executor.rollback();
          break;
        default:
          assert(false, 'Unknown TransactionControl');
      }
    } finally {
      _releaseExecutor(executorId!);
    }
  }

  void _releaseExecutor(int id) {
    _managedExecutors.remove(id);
    _executorBacklog.remove(id);
    _notifyActiveExecutorUpdated();
  }

  Future<void> _waitForTurn(int? transactionId) {
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
  int schemaVersion = 0; // will be overridden by client requests

  _IsolateDelegatedUser(this.server);

  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {
    final id = server._putExecutor(executor, beforeCurrent: true);
    try {
      await server.firstClient!.request(_RunBeforeOpen(details, id));
    } finally {
      server._releaseExecutor(id);
    }
  }
}
