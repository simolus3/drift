import 'dart:async';

import '../connection.dart';
import '../result_set.dart';
import 'channel.dart';
import 'protocol.dart';

/// The client part of a remote drift communication scheme.
final class DriftClient {
  final DriftChannel _channel;

  DriftClient(this._channel);
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

  final Completer _closed = Completer();

  int get _sessionId => details.sessionId;

  _RemoteSession(this.client, this.details);

  @override
  Future<void> close() async {
    if (!_closed.isCompleted) {
      _closed.complete(client._channel
          .request((id) => CloseSessionRequest(id, sessionId: _sessionId)));
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
