part of 'moor_isolate.dart';

/// A request without further parameters
enum _NoArgsRequest {
  /// Sent from the client to the server. The server will reply with the
  /// [SqlTypeSystem] of the [_MoorServer.connection] it's managing.
  getTypeSystem,

  /// Sent from the client to start a transaction. The server must reply with an
  /// integer, which serves as an identifier for the transaction in
  /// [_ExecuteQuery.executorId].
  startTransaction,

  /// Close the background isolate, disconnect all clients, release all
  /// associated resources
  terminateAll,
}

enum _StatementMethod {
  custom,
  deleteOrUpdate,
  insert,
  select,
}

enum _TransactionControl {
  commit,
  rollback,
}

/// Sent from the client to run a sql query. The server replies with the
/// result.
class _ExecuteQuery {
  final _StatementMethod method;
  final String sql;
  final List<dynamic> args;
  final int executorId;

  _ExecuteQuery(this.method, this.sql, this.args, [this.executorId]);

  @override
  String toString() {
    if (executorId != null) {
      return '$method: $sql with $args (@$executorId)';
    }
    return '$method: $sql with $args';
  }
}

/// Sent from the client to run a list of [BatchedStatement]s.
class _ExecuteBatchedStatement {
  final List<BatchedStatement> stmts;
  final int executorId;

  _ExecuteBatchedStatement(this.stmts, [this.executorId]);
}

/// Sent from the client to commit or rollback a transaction
class _RunTransactionAction {
  final _TransactionControl control;
  final int transactionId;

  _RunTransactionAction(this.control, this.transactionId);
}

/// Sent from the client to the server. The server should open the underlying
/// database connection, using the [schemaVersion].
class _EnsureOpen {
  final int schemaVersion;
  final int executorId;

  _EnsureOpen(this.schemaVersion, this.executorId);
}

/// Sent from the server to the client when it should run the before open
/// callback.
class _RunBeforeOpen {
  final OpeningDetails details;
  final int createdExecutor;

  _RunBeforeOpen(this.details, this.createdExecutor);
}

/// Sent to notify that a previous query has updated some tables. When a server
/// receives this message, it replies with `null` but forwards a new request
/// with this payload to all connected clients.
class _NotifyTablesUpdated {
  final List<TableUpdate> updates;

  _NotifyTablesUpdated(this.updates);
}
