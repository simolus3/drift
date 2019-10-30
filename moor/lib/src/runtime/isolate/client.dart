part of 'moor_isolate.dart';

class _MoorClient {
  final IsolateCommunication _channel;
  final SqlTypeSystem typeSystem;

  DatabaseConnection _connection;

  GeneratedDatabase get connectedDb => _connection.executor.databaseInfo;

  SqlExecutor get executor => _connection.executor.runCustom;

  _MoorClient(this._channel, this.typeSystem) {
    _connection = DatabaseConnection(
      typeSystem,
      _IsolateQueryExecutor(this),
      null,
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
    }
  }
}

class _IsolateQueryExecutor extends QueryExecutor {
  final _MoorClient client;

  _IsolateQueryExecutor(this.client);

  @override
  set databaseInfo(GeneratedDatabase db) {
    super.databaseInfo = db;
    client._channel.request(_SetSchemaVersion(db.schemaVersion));
  }

  @override
  TransactionExecutor beginTransaction() {
    throw UnsupportedError(
        'Transactions are not currently supported over isolates');
  }

  @override
  Future<bool> ensureOpen() {
    return client._channel.request<bool>(_NoArgsRequest.ensureOpen);
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) async {
    // todo optimize this case
    for (var stmt in statements) {
      for (var boundArgs in stmt.variables) {
        await runCustom(stmt.sql, boundArgs);
      }
    }
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

  @override
  Future<void> close() {
    client._channel.close();
    return Future.value();
  }
}
