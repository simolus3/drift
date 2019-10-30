part of 'moor_isolate.dart';

class _MoorServer {
  final Server server;

  DatabaseConnection connection;
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
        // the following are requests which are handled on the client side
        case _NoArgsRequest.runOnCreate:
          throw UnsupportedError(
              'This operation needs to be run on the client');
      }
    } else if (payload is _SetSchemaVersion) {
      _fakeDb.schemaVersion = payload.schemaVersion;
      return null;
    } else if (payload is _ExecuteQuery) {
      return _runQuery(payload.method, payload.sql, payload.args);
    }
  }

  Future<dynamic> _runQuery(_StatementMethod method, String sql, List args) {
    final executor = connection.executor;
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
