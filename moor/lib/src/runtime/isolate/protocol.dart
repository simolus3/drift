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
}

enum _StatementMethod {
  custom,
  deleteOrUpdate,
  insert,
  select,
}

/// Sent from the client to run a sql query. The server replies with the
/// result.
class _ExecuteQuery {
  final _StatementMethod method;
  final String sql;
  final List<dynamic> args;

  _ExecuteQuery(this.method, this.sql, this.args);

  @override
  String toString() {
    return '$method: $sql with $args';
  }
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

class _RunBeforeOpen {
  final OpeningDetails details;

  _RunBeforeOpen(this.details);
}
