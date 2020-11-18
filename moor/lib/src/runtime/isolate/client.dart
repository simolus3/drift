part of 'moor_isolate.dart';

class _MoorClient {
  final IsolateCommunication _channel;
  final SqlTypeSystem typeSystem;

  late final _IsolateStreamQueryStore _streamStore =
      _IsolateStreamQueryStore(this);
  late final DatabaseConnection _connection = DatabaseConnection(
    typeSystem,
    _IsolateQueryExecutor(this),
    _streamStore,
  );

  late QueryExecutorUser _connectedDb;

  _MoorClient(this._channel, this.typeSystem) {
    _channel.setRequestHandler(_handleRequest);
  }

  static Future<_MoorClient> connect(
      MoorIsolate isolate, bool isolateDebugLog) async {
    final connection = await IsolateCommunication.connectAsClient(
        isolate.connectPort, const _MoorCodec(), isolateDebugLog);

    final typeSystem =
        await connection.request<SqlTypeSystem>(_NoArgsRequest.getTypeSystem);
    return _MoorClient(connection, typeSystem);
  }

  dynamic _handleRequest(Request request) {
    final payload = request.payload;

    if (payload is _RunBeforeOpen) {
      final executor = _IsolateQueryExecutor(this, payload.createdExecutor);
      return _connectedDb.beforeOpen(executor, payload.details);
    } else if (payload is _NotifyTablesUpdated) {
      _streamStore.handleTableUpdates(payload.updates.toSet(), true);
    }
  }
}

abstract class _BaseExecutor extends QueryExecutor {
  final _MoorClient client;
  int? _executorId;

  _BaseExecutor(this.client, [this._executorId]);

  @override
  Future<void> runBatched(BatchedStatements statements) {
    return client._channel
        .request(_ExecuteBatchedStatement(statements, _executorId));
  }

  Future<T> _runRequest<T>(_StatementMethod method, String sql, List? args) {
    return client._channel
        .request<T>(_ExecuteQuery(method, sql, args ?? const [], _executorId));
  }

  @override
  Future<void> runCustom(String statement, [List? args]) {
    return _runRequest(
      _StatementMethod.custom,
      statement,
      args,
    );
  }

  @override
  Future<int> runDelete(String statement, List args) {
    return _runRequest(_StatementMethod.deleteOrUpdate, statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    return _runRequest(_StatementMethod.deleteOrUpdate, statement, args);
  }

  @override
  Future<int> runInsert(String statement, List args) {
    return _runRequest(_StatementMethod.insert, statement, args);
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(String statement, List args) {
    return _runRequest(_StatementMethod.select, statement, args);
  }
}

class _IsolateQueryExecutor extends _BaseExecutor {
  _IsolateQueryExecutor(_MoorClient client, [int? executorId])
      : super(client, executorId);

  Completer<void>? _setSchemaVersion;

  @override
  TransactionExecutor beginTransaction() {
    return _TransactionIsolateExecutor(client, _executorId);
  }

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async {
    client._connectedDb = user;
    if (_setSchemaVersion != null) {
      await _setSchemaVersion!.future;
      _setSchemaVersion = null;
    }
    return client._channel
        .request<bool>(_EnsureOpen(user.schemaVersion, _executorId));
  }

  @override
  Future<void> close() {
    if (!client._channel.isClosed) {
      client._channel.close();
    }

    return Future.value();
  }
}

class _TransactionIsolateExecutor extends _BaseExecutor
    implements TransactionExecutor {
  final int? _outerExecutorId;

  _TransactionIsolateExecutor(_MoorClient client, this._outerExecutorId)
      : super(client);

  Completer<bool>? _pendingOpen;
  bool _done = false;

  @override
  TransactionExecutor beginTransaction() {
    throw UnsupportedError('Nested transactions');
  }

  @override
  Future<bool> ensureOpen(_) {
    assert(
      !_done,
      'Transaction used after it was closed. Are you missing an await '
      'somewhere?',
    );

    final completer = _pendingOpen ??= Completer()..complete(_openAtServer());
    return completer.future;
  }

  Future<bool> _openAtServer() async {
    _executorId = await client._channel.request<int>(
        _RunTransactionAction(_TransactionControl.begin, _outerExecutorId));
    return true;
  }

  Future<void> _sendAction(_TransactionControl action) {
    return client._channel.request(_RunTransactionAction(action, _executorId));
  }

  @override
  Future<void> rollback() async {
    // don't do anything if the transaction isn't open yet
    if (_pendingOpen == null) return;

    await _sendAction(_TransactionControl.rollback);
    _done = true;
  }

  @override
  Future<void> send() async {
    // don't do anything if the transaction isn't open yet
    if (_pendingOpen == null) return;

    await _sendAction(_TransactionControl.commit);
    _done = true;
  }
}

class _IsolateStreamQueryStore extends StreamQueryStore {
  final _MoorClient client;
  final Set<Completer> _awaitingUpdates = {};

  _IsolateStreamQueryStore(this.client);

  @override
  void handleTableUpdates(Set<TableUpdate> updates,
      [bool comesFromServer = false]) {
    if (comesFromServer) {
      super.handleTableUpdates(updates);
    } else {
      // requests are async, but the function is synchronous. We await that
      // future in close()
      final completer = Completer<void>();
      _awaitingUpdates.add(completer);

      completer.complete(
          client._channel.request(_NotifyTablesUpdated(updates.toList())));

      completer.future.catchError((_) {
        // we don't care about errors if the connection is closed before the
        // update is dispatched. Why?
      }, test: (e) => e is ConnectionClosedException).whenComplete(() {
        _awaitingUpdates.remove(completer);
      });
    }
  }

  @override
  Future<void> close() async {
    await super.close();

    // create a copy because awaiting futures in here mutates the set
    final updatesCopy = _awaitingUpdates.map((e) => e.future).toList();
    await Future.wait(updatesCopy);
  }
}
