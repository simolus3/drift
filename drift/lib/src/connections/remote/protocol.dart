@internal
// All of this is drift-internal and not exported, so:
// ignore_for_file: public_member_api_docs
library;

import 'package:meta/meta.dart';

import '../../runtime/streams/update_rules.dart';
import '../connection.dart';
import '../result_set.dart';

sealed class ProtocolMessage {
  String debugToString();
}

sealed class Request<Res extends Response> implements ProtocolMessage {
  final int id;

  Request(this.id);
}

sealed class Response implements ProtocolMessage {
  final int requestId;

  Response(this.requestId);
}

final class SimpleResponse extends Response {
  SimpleResponse(super.requestId);

  @override
  String debugToString() {
    return 'SimpleResponse($requestId)';
  }
}

final class ErrorResponse implements ProtocolMessage {
  final int requestId;
  final Object error;
  final StackTrace? stackTrace;

  ErrorResponse(this.requestId, this.error, [this.stackTrace]);

  @override
  String debugToString() => toString();

  @override
  String toString() {
    return 'ErrorResponse (id = $requestId): $error at $stackTrace';
  }
}

final class CancelledResponse implements ProtocolMessage {
  final int requestId;

  CancelledResponse(this.requestId);

  @override
  String debugToString() {
    return 'CancelledResponse($requestId)';
  }
}

final class ClientInitialize extends Request<SessionDetails> {
  ClientInitialize(super.id);

  @override
  String debugToString() {
    return 'CllientInitialize($id)';
  }
}

final class SessionDetails extends Response {
  final int sessionId;

  /// Whether the session has a [DriftSession.root].
  final bool isRoot;

  /// Whether the session is a [DriftTransactionParent].
  final bool isDriftTransactionParent;

  /// Whether the session is a [DriftTransactionSession].
  final bool isTransaction;

  /// Whether the session is a [DriftSessionWithInternalLocks].
  final bool isDriftSessionWithInternalLocks;

  SessionDetails(
    super.requestId, {
    required this.sessionId,
    required this.isRoot,
    required this.isDriftTransactionParent,
    required this.isTransaction,
    required this.isDriftSessionWithInternalLocks,
  });

  @override
  String debugToString() {
    return 'SessionDetails($requestId, $sessionId, root: $isRoot, tx parent $isDriftTransactionParent, tx: $isTransaction, locks: $isDriftSessionWithInternalLocks)';
  }
}

final class ExecuteRequest extends Request<ExecuteResponse> {
  final StatementInfo statement;
  final int sessionId;

  ExecuteRequest(super.id, {required this.sessionId, required this.statement});

  @override
  String debugToString() {
    return 'ExecuteRequest($id, $sessionId, $statement)';
  }
}

final class ExecuteBatchRequest extends Request<ExecuteResponse> {
  final StatementBatch batch;
  final int sessionId;

  ExecuteBatchRequest(super.id, {required this.sessionId, required this.batch});

  @override
  String debugToString() {
    return 'ExecuteBatchRequest($id, $sessionId, $batch)';
  }
}

final class ExecuteResponse extends Response {
  final List<QueryResult> result;

  ExecuteResponse(super.requestId, {required this.result});

  @override
  String debugToString() {
    return 'ExecuteResponse($requestId, $result)';
  }
}

/// Requests to call [DriftSessionWithInternalLocks.exclusive].
final class StartExclusiveRequest extends Request<SessionDetails> {
  final int parentId;

  StartExclusiveRequest(super.id, {required this.parentId});

  @override
  String debugToString() {
    return 'StartExclusiveRequest($id, $parentId)';
  }
}

/// Requests to call [DriftTransactionParent.begin].
final class BeginTransactionRequest extends Request<SessionDetails> {
  final int parentId;
  final TransactionOptions options;

  BeginTransactionRequest(super.id,
      {required this.parentId, required this.options});

  @override
  String debugToString() {
    return 'BeginTransactionRequest($id, $parentId, $options)';
  }
}

final class GetSchemaVersion extends Request<SchemaVersionResponse> {
  final int sessionId;

  GetSchemaVersion(
    super.id, {
    required this.sessionId,
  });

  @override
  String debugToString() {
    return 'GetSchemaVersion($id, $sessionId)';
  }
}

final class SchemaVersionResponse extends Response {
  final int schemaVersion;

  SchemaVersionResponse(super.requestId, this.schemaVersion);

  @override
  String debugToString() {
    return 'SchemaVersionResponse($requestId, $schemaVersion)';
  }
}

final class WriteSchemaVersion extends Request<Response> {
  final int sessionId;
  final int schemaVersion;

  WriteSchemaVersion(super.id,
      {required this.sessionId, required this.schemaVersion});

  @override
  String debugToString() {
    return 'WriteSchemaVersion($id, $sessionId, $schemaVersion)';
  }
}

enum CloseMode { close, rollback, commit }

/// Requests to call [DriftSession.close]
final class CloseSessionRequest extends Request<Response> {
  /// The session id to close.
  final int sessionId;
  final CloseMode mode;

  CloseSessionRequest(super.id,
      {required this.sessionId, this.mode = CloseMode.close});

  @override
  String debugToString() {
    return 'CloseSessionRequest($id, $sessionId, $mode)';
  }
}

/// Requests to shut the entire server down.
final class ShutdownServerRequest extends Request<Response> {
  ShutdownServerRequest(super.id);

  @override
  String debugToString() {
    return 'ShutdownServerRequest($id)';
  }
}

/// Notification that the [DriftSession.closed] future has completed on a
/// session the client is interested in.
final class NotifySessionClosed extends ProtocolMessage {
  final int sessionId;

  NotifySessionClosed({required this.sessionId});

  @override
  String debugToString() {
    return 'NotifySessionClosed($sessionId)';
  }
}

/// Sent to notify that a previous query has updated some tables. When a server
/// receives this message, it forwards it to all connected clients.
final class NotifyTablesUpdated extends ProtocolMessage {
  final List<TableUpdate> updates;

  NotifyTablesUpdated(this.updates);

  @override
  String debugToString() {
    return 'NotifyTableUpdated($updates)';
  }
}
