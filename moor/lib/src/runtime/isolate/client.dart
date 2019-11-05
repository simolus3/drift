part of 'moor_isolate.dart';

class _MoorClient {
  final IsolateCommunication _channel;
  final SqlTypeSystem typeSystem;
  _IsolateStreamQueryStore _streamStore;

  DatabaseConnection _connection;

  GeneratedDatabase get connectedDb => _connection.executor.databaseInfo;

  SqlExecutor get executor => _connection.executor.runCustom;

  _MoorClient(this._channel, this.typeSystem) {
    _streamStore = _IsolateStreamQueryStore(this);

    _connection = DatabaseConnection(
      typeSystem,
      _IsolateQueryExecutor(this),
      _streamStore,
    );
    _channel.setRequestHandler(_handleRequest);
  }

  static Future<_MoorClient> connect(
      MoorIsolate isolate, bool isolateDebugLog) async {
    final connection = await IsolateCommunication.connectAsClient(
        isolate._server, isolateDebugLog);

    final typeSystem =
        await connection.request<SqlTypeSystem>(_NoArgsRequest.getTypeSystem);
    return _MoorClient(connection, typeSystem);
  }

  dynamic _handleRequest(Request request) {
    final payload = request.payload;

    if (payload is _NoArgsRequest) {
      switch (payload) {
        case _NoArgsRequest.runOnCreate:
          return connectedDb.handleDatabaseCreation(executor: executor);
        default:
          throw UnsupportedError('This operation must be run on the server');
      }
    } else if (payload is _RunOnUpgrade) {
      return connectedDb.handleDatabaseVersionChange(
        executor: executor,
        from: payload.versionBefore,
        to: payload.versionNow,
      );
    } else if (payload is _RunBeforeOpen) {
      return connectedDb.beforeOpenCallback(
          _connection.executor, payload.details);
    } else if (payload is _NotifyTablesUpdated) {
      _streamStore.handleTableUpdatesByName(payload.updatedTables.toSet());
    }
  }
}

abstract class _BaseExecutor extends QueryExecutor {
  final _MoorClient client;
  int _transactionId;

  _BaseExecutor(this.client);

  @override
  Future<void> runBatched(List<BatchedStatement> statements) {
    return client._channel.request(_ExecuteBatchedStatement(statements));
  }

  Future<T> _runRequest<T>(_StatementMethod method, String sql, List args) {
    return client._channel.request<T>(_ExecuteQuery(method, sql, args));
  }

  @override
  Future<void> runCustom(String statement, [List args]) {
    return _runRequest(_StatementMethod.custom, statement, args);
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
  _IsolateQueryExecutor(_MoorClient client) : super(client);

  @override
  set databaseInfo(GeneratedDatabase db) {
    super.databaseInfo = db;
    client._channel.request(_SetSchemaVersion(db.schemaVersion));
  }

  @override
  TransactionExecutor beginTransaction() {
    return _TransactionIsolateExecutor(client);
  }

  @override
  Future<bool> ensureOpen() {
    return client._channel.request<bool>(_NoArgsRequest.ensureOpen);
  }

  @override
  Future<void> close() {
    client._channel.close();
    return Future.value();
  }
}

class _TransactionIsolateExecutor extends _BaseExecutor
    implements TransactionExecutor {
  _TransactionIsolateExecutor(_MoorClient client) : super(client);

  bool _pendingOpen = false;

  // nested transactions aren't supported
  @override
  TransactionExecutor beginTransaction() => null;

  @override
  Future<bool> ensureOpen() {
    if (_transactionId == null && !_pendingOpen) {
      _pendingOpen = true;
      return _openAtServer().then((_) => true);
    }
    return Future.value(true);
  }

  Future _openAtServer() async {
    _transactionId =
        await client._channel.request(_NoArgsRequest.startTransaction) as int;
    _pendingOpen = false;
  }

  Future<void> _sendAction(_TransactionControl action) {
    return client._channel
        .request(_RunTransactionAction(action, _transactionId));
  }

  @override
  Future<void> rollback() {
    return _sendAction(_TransactionControl.rollback);
  }

  @override
  Future<void> send() {
    return _sendAction(_TransactionControl.commit);
  }
}

class _IsolateStreamQueryStore extends StreamQueryStore {
  final _MoorClient client;

  _IsolateStreamQueryStore(this.client);

  @override
  Future<void> handleTableUpdates(Set<TableInfo> tables) {
    // we're not calling super.handleTableUpdates because the server will send
    // a notification of those tables to all clients, including the one who sent
    // this. When we get that reply, we update the tables.
    // Note that we're not running into an infinite feedback loop because the
    // client will call handleTableUpdatesByName. That's kind of a hack.
    return client._channel.request(
        _NotifyTablesUpdated(tables.map((t) => t.actualTableName).toList()));
  }
}
