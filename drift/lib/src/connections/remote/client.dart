import 'dart:async';

import '../../runtime/streams/store.dart';
import '../../runtime/streams/store_impl.dart';
import '../../runtime/streams/update_rules.dart';
import '../connection.dart';
import '../result_set.dart';
import 'channel.dart';
import 'protocol.dart';

/// The client part of a remote drift communication scheme.
final class DriftClient {
  final DriftChannel _channel;
  final Object? _tag;

  /// Whether to operate in "single-client mode".
  ///
  /// In this mode, no table update notifications are sent to the server.
  final bool singleClientMode;

  /// A [StreamQueryStore] that takes queries from other clients attached to the
  /// same server into account.
  StreamQueryStore get streamQueries => _streamQueries;

  late StreamQueryStore _streamQueries;

  /// Creates a new drift client from the underlying [DriftChannel].
  DriftClient(this._channel, this.singleClientMode, this._tag) {
    _streamQueries = _RemoteStreamQueryStore(this);
  }

  /// Sends a [ClientInitialize] request to the server and wraps the returned
  /// [SessionDetails] in a [DriftSession] implementation.
  Future<DriftSession> requestRootSession() async {
    final details = await _channel
        .request<ClientInitialize, SessionDetails>(ClientInitialize.new);

    return _RemoteSession(this, details, isOutermostSession: true);
  }
}

final class _RemoteSession
    implements
        DriftSession,
        DriftTransactionParent,
        DriftTransactionSession,
        DriftRootSession,
        DriftSessionWithInternalLocks {
  final DriftClient client;
  final SessionDetails details;

  /// Whether this session is the one returned by
  /// [DriftClient.requestRootSession].
  final bool isOutermostSession;

  final Completer _closed = Completer();

  int get _sessionId => details.sessionId;

  _RemoteSession(this.client, this.details, {this.isOutermostSession = false});

  @override
  Object? get tag => isOutermostSession ? client._tag : null;

  @override
  Future<void> close() async {
    if (!_closed.isCompleted) {
      if (isOutermostSession) {
        final future = client.singleClientMode
            ? client._channel
                .request((id) => CloseSessionRequest(id, sessionId: _sessionId))
            // Don't close the top-level session, other clients may still be
            // using it.
            : Future.value(null);

        _closed.complete(future.whenComplete(() async {
          await client._channel.close();
        }));
      } else {
        // Just close the sub-session
        _closed.complete(client._channel
            .request((id) => CloseSessionRequest(id, sessionId: _sessionId)));
      }
    }

    await closed;
  }

  @override
  Future<void> get closed => _closed.future;

  @override
  Future<DriftSession> begin(TransactionOptions options) async {
    final response = await client._channel
        .request<BeginTransactionRequest, SessionDetails>((id) =>
            BeginTransactionRequest(id,
                parentId: _sessionId, options: options));
    return _RemoteSession(client, response);
  }

  @override
  Future<void> commit() async {
    await client._channel.request((id) =>
        CloseSessionRequest(id, sessionId: _sessionId, mode: CloseMode.commit));
  }

  @override
  Future<DriftSession> exclusive() async {
    final response = await client._channel
        .request<StartExclusiveRequest, SessionDetails>(
            (id) => StartExclusiveRequest(id, parentId: _sessionId));
    return _RemoteSession(client, response);
  }

  @override
  Future<QueryResult> execute(StatementInfo statement) async {
    final response = await client._channel
        .request<ExecuteRequest, ExecuteResponse>((id) =>
            ExecuteRequest(id, sessionId: _sessionId, statement: statement));
    return response.result.single;
  }

  @override
  Future<List<QueryResult>> executeBatch(List<StatementBatch> batch) async {
    final response = await client._channel
        .request<ExecuteBatchRequest, ExecuteResponse>((id) =>
            ExecuteBatchRequest(id, sessionId: _sessionId, batch: batch));
    return response.result;
  }

  @override
  bool get isClosed => _closed.isCompleted;

  @override
  DriftSessionWithInternalLocks? get locks =>
      details.isDriftSessionWithInternalLocks ? this : null;

  @override
  Future<void> rollback() async {
    await client._channel.request((id) => CloseSessionRequest(id,
        sessionId: _sessionId, mode: CloseMode.rollback));
  }

  @override
  DriftRootSession? get root => details.isRoot ? this : null;

  @override
  Future<int> get schemaVersion async {
    final response = await client._channel
        .request<GetSchemaVersion, SchemaVersionResponse>(
            (id) => GetSchemaVersion(id, sessionId: _sessionId));
    return response.schemaVersion;
  }

  @override
  DriftTransactionSession? get transaction =>
      details.isTransaction ? this : null;

  @override
  DriftTransactionParent? get transactionParent =>
      details.isDriftTransactionParent ? this : null;

  @override
  Future<void> writeSchemaVersion(int version) async {
    await client._channel.request((id) => WriteSchemaVersion(
          id,
          sessionId: _sessionId,
          schemaVersion: version,
        ));
  }
}

final class _RemoteStreamQueryStore extends LocalStreamQueryStore {
  final DriftClient _client;
  final Set<Completer> _awaitingUpdates = {};

  _RemoteStreamQueryStore(this._client);

  @override
  void handleTableUpdates(Set<TableUpdate> updates,
      [bool comesFromServer = false]) {
    super.handleTableUpdates(updates);

    if (!comesFromServer && !_client.singleClientMode) {
      // Also notify the server (so that queries on other connections have a
      // chance to update as well). Since this method is synchronous but the
      // connection isn't, we store this request in a completer and await
      // pending operations in close() (which is async).
      final completer = Completer<void>();
      _awaitingUpdates.add(completer);

      _client._channel.send(NotifyTablesUpdated(updates.toList()));

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
