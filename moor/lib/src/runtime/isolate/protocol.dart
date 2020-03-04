part of 'moor_isolate.dart';

/// A request without further parameters
enum _NoArgsRequest {
  /// Sent from the client to the server. The server will reply with the
  /// [SqlTypeSystem] of the [_MoorServer.connection] it's managing.
  getTypeSystem,

  /// Sent from the client to the server. The server will reply with
  /// [QueryExecutor.ensureOpen], based on the [_MoorServer.connection].
  ensureOpen,

  /// Sent from the server to a client. The client should run the on create
  /// method of the attached database
  runOnCreate,

  /// Sent from the client to start a transaction. The server must reply with an
  /// integer, which serves as an identifier for the transaction in
  /// [_ExecuteQuery.transactionId].
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
  final int transactionId;

  _ExecuteQuery(this.method, this.sql, this.args, [this.transactionId]);

  @override
  String toString() {
    if (transactionId != null) {
      return '$method: $sql with $args (@$transactionId)';
    }
    return '$method: $sql with $args';
  }
}

/// Sent from the client to run a list of [BatchedStatement]s.
class _ExecuteBatchedStatement {
  final List<BatchedStatement> stmts;
  final int transactionId;

  _ExecuteBatchedStatement(this.stmts, [this.transactionId]);
}

/// Sent from the client to commit or rollback a transaction
class _RunTransactionAction {
  final _TransactionControl control;
  final int transactionId;

  _RunTransactionAction(this.control, this.transactionId);
}

/// Sent from the client to notify the server of the
/// [GeneratedDatabase.schemaVersion] used by the attached database.
class _SetSchemaVersion {
  final int schemaVersion;

  _SetSchemaVersion(this.schemaVersion);
}

/// Sent from the server to the client. The client should run a database upgrade
/// migration.
class _RunOnUpgrade {
  final int versionBefore;
  final int versionNow;

  _RunOnUpgrade(this.versionBefore, this.versionNow);
}

/// Sent from the server to the client when it should run the before open
/// callback.
class _RunBeforeOpen {
  final OpeningDetails details;

  _RunBeforeOpen(this.details);
}

/// Sent to notify that a previous query has updated some tables. When a server
/// receives this message, it replies with `null` but forwards a new request
/// with this payload to all connected clients.
class _NotifyTablesUpdated {
  final List<TableUpdate> updates;

  _NotifyTablesUpdated(this.updates);
}
