part of 'moor_isolate.dart';

class _MoorServer {
  final Server server;

  DatabaseConnection connection;
  final Map<int, TransactionExecutor> _transactions = {};
  int _currentTransaction = 0;
  _FakeDatabase _fakeDb;

  ServerKey get key => server.key;

  _MoorServer(DatabaseOpener opener) : server = Server() {
    server.openedConnections.listen((connection) {
      connection.setRequestHandler(_handleRequest);
    });
    connection = opener();

    _fakeDb = _FakeDatabase(connection, this);
    connection.executor.databaseInfo = _fakeDb;
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
        case _NoArgsRequest.ensureOpen:
          return connection.executor.ensureOpen();
        case _NoArgsRequest.startTransaction:
          return _spawnTransaction();
        case _NoArgsRequest.terminateAll:
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
      return connection.executor.runBatched(payload.stmts);
    } else if (payload is _NotifyTablesUpdated) {
      for (var connected in server.currentChannels) {
        connected.request(payload);
      }
    } else if (payload is _RunTransactionAction) {
      return _transactionControl(payload.control, payload.transactionId);
    }
  }

  Future<dynamic> _runQuery(
      _StatementMethod method, String sql, List args, int transactionId) {
    final executor = transactionId != null
        ? _transactions[transactionId]
        : connection.executor;

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

  int _spawnTransaction() {
    final id = _currentTransaction++;
    _transactions[id] = connection.executor.beginTransaction();
    return id;
  }

  Future<void> _transactionControl(
      _TransactionControl action, int transactionId) {
    final transaction = _transactions[transactionId];
    _transactions.remove(transactionId);
    switch (action) {
      case _TransactionControl.commit:
        return transaction.send();
      case _TransactionControl.rollback:
        return transaction.rollback();
    }
    throw AssertionError("Can't happen");
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
      QueryExecutor executor, OpeningDetails details) {
    return server.firstClient.request(_RunBeforeOpen(details));
  }
}
