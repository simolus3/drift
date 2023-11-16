import 'dart:async';

import 'package:drift/src/runtime/api/runtime_api.dart';
import 'package:drift/src/runtime/executor/executor.dart';
import 'package:drift/src/runtime/executor/stream_queries.dart';
import 'package:drift/src/runtime/query_builder/query_builder.dart';
import 'package:stream_channel/stream_channel.dart';

import '../runtime/cancellation_zone.dart';
import 'communication.dart';
import 'protocol.dart';

/// The client part of a remote drift communication scheme.
class DriftClient {
  final DriftCommunication _channel;

  SqlDialect _serverDialect = SqlDialect.sqlite;
  final Completer<ServerInfo> _serverInfo = Completer();

  /// Waits for the first [ServerInfo] message to this client.
  Future<ServerInfo> get serverInfo => _serverInfo.future;

  /// Whether we know that only a single client will use the database server.
  ///
  /// In this case, we shutdown the server after the client disconnects and
  /// can avoid forwarding stream query updaten notifications.
  final bool _singleClientMode;

  late final _RemoteStreamQueryStore _streamStore =
      _RemoteStreamQueryStore(this);

  /// The resulting database connection. Operations on this connection are
  /// relayed through the remote communication channel.
  late final DatabaseConnection connection = DatabaseConnection(
    _RemoteQueryExecutor(this),
    streamQueries: _streamStore,
  );

  late QueryExecutorUser _connectedDb;

  /// Starts relaying database operations over the request channel.
  DriftClient(
    StreamChannel<Object?> channel,
    bool debugLog,
    bool serialize,
    this._singleClientMode,
  ) : _channel = DriftCommunication(channel,
            debugLog: debugLog, serialize: serialize) {
    _channel.setRequestHandler(_handleRequest);
  }

  dynamic _handleRequest(Request request) {
    final payload = request.payload;

    if (payload is RunBeforeOpen) {
      final executor = _RemoteQueryExecutor(this, payload.createdExecutor);
      return _connectedDb.beforeOpen(executor, payload.details);
    } else if (payload is NotifyTablesUpdated) {
      _streamStore.handleTableUpdates(payload.updates.toSet(), true);
    } else if (payload is ServerInfo) {
      _serverDialect = payload.dialect;
      _serverInfo.complete(payload);
    }
  }
}

abstract class _BaseExecutor extends QueryExecutor {
  final DriftClient client;
  int? _executorId;

  // ignore: unused_element, https://github.com/dart-lang/sdk/issues/49007
  _BaseExecutor(this.client, [this._executorId]);

  @override
  SqlDialect get dialect => client._serverDialect;

  @override
  Future<void> runBatched(BatchedStatements statements) {
    return client._channel
        .request(ExecuteBatchedStatement(statements, _executorId));
  }

  Future<T> _runRequest<T>(
      StatementMethod method, String sql, List<Object?>? args) {
    // fast path: If the operation has already been cancelled, don't bother
    // sending a request in the first place
    checkIfCancelled();

    final id = client._channel.newRequestId();
    // otherwise, send the request now and cancel it later, if that's desired
    doOnCancellation(() {
      client._channel.request<void>(RequestCancellation(id)).onError((_, __) {
        // Couldn't be cancelled. Ok then.
      });
    });

    return client._channel.request<T>(
      ExecuteQuery(method, sql, args ?? const [], _executorId),
      requestId: id,
    );
  }

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) {
    return _runRequest(
      StatementMethod.custom,
      statement,
      args,
    );
  }

  @override
  Future<int> runDelete(String statement, List<Object?> args) {
    return _runRequest(StatementMethod.deleteOrUpdate, statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) {
    return _runRequest(StatementMethod.deleteOrUpdate, statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) {
    return _runRequest(StatementMethod.insert, statement, args);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
      String statement, List<Object?> args) async {
    final result = await _runRequest<SelectResult>(
        StatementMethod.select, statement, args);

    return result.rows;
  }
}

class _RemoteQueryExecutor extends _BaseExecutor {
  _RemoteQueryExecutor(super.client, [super.executorId]);

  Completer<void>? _setSchemaVersion;
  Future<bool>? _serverIsOpen;

  @override
  TransactionExecutor beginTransaction() {
    return _RemoteTransactionExecutor(client, _executorId);
  }

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async {
    client._connectedDb = user;
    if (_setSchemaVersion != null) {
      await _setSchemaVersion!.future;
      _setSchemaVersion = null;
    }

    return _serverIsOpen ??= client._channel
        .request<bool>(EnsureOpen(user.schemaVersion, _executorId));
  }

  @override
  Future<void> close() {
    final channel = client._channel;

    if (!channel.isClosed) {
      if (client._singleClientMode) {
        return channel
            .request<void>(NoArgsRequest.terminateAll)
            .onError<ConnectionClosedException>((error, stackTrace) => null)
            .whenComplete(channel.close);
      } else {
        return channel.close();
      }
    }

    return Future.value();
  }
}

class _RemoteTransactionExecutor extends _BaseExecutor
    implements TransactionExecutor {
  final int? _outerExecutorId;

  _RemoteTransactionExecutor(super.client, this._outerExecutorId);

  Completer<bool>? _pendingOpen;
  bool _done = false;

  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  bool get supportsNestedTransactions => true;

  @override
  TransactionExecutor beginTransaction() {
    return _RemoteTransactionExecutor(client, _executorId);
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
        RunTransactionAction(TransactionControl.begin, _outerExecutorId));
    return true;
  }

  Future<void> _sendAction(TransactionControl action) {
    return client._channel.request(RunTransactionAction(action, _executorId));
  }

  @override
  Future<void> rollback() async {
    // don't do anything if the transaction isn't open yet
    if (_pendingOpen == null) return;

    await _sendAction(TransactionControl.rollback);
    _done = true;
  }

  @override
  Future<void> send() async {
    // don't do anything if the transaction isn't open yet
    if (_pendingOpen == null) return;

    await _sendAction(TransactionControl.commit);
    _done = true;
  }
}

class _RemoteStreamQueryStore extends StreamQueryStore {
  final DriftClient _client;
  final Set<Completer> _awaitingUpdates = {};

  _RemoteStreamQueryStore(this._client);

  @override
  void handleTableUpdates(Set<TableUpdate> updates,
      [bool comesFromServer = false]) {
    super.handleTableUpdates(updates);

    if (!comesFromServer && !_client._singleClientMode) {
      // Also notify the server (so that queries on other connections have a
      // chance to update as well). Since this method is synchronous but the
      // connection isn't, we store this request in a completer and await
      // pending operations in close() (which is async).
      final completer = Completer<void>();
      _awaitingUpdates.add(completer);

      completer.complete(
          _client._channel.request(NotifyTablesUpdated(updates.toList())));

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
