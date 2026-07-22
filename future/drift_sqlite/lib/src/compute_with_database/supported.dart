import 'dart:async';
import 'dart:isolate';

import 'package:drift3/drift.dart';
import 'package:sqlite3_connection_pool/sqlite3_connection_pool.dart';

import '../connection/pool.dart';
import 'unsupported.dart' as fallback;

/// Spawns a short-lived isolate to run the [computation] with a drift
/// database.
Future<Ret>
computeWithDatabaseImplementation<Ret, DB extends GeneratedDatabase>({
  required FutureOr<Ret> Function(DB) computation,
  required DB Function(DriftConnection) connect,
  required DB database,
}) async {
  final session = await database.currentSession();
  final dialect = database.dialect;

  if (session.tag case final SqlitePoolSession pool) {
    final name = pool.pool.name;

    return await _runWithDatabase(
      computation: computation,
      connect: connect,
      dialect: dialect,
      name: name,
    );
  } else {
    return fallback.computeWithDatabaseImplementation(
      computation: computation,
      connect: connect,
      database: database,
    );
  }
}

Future<T> _runWithDatabase<T, DB extends GeneratedDatabase>({
  required FutureOr<T> Function(DB) computation,
  required DB Function(DriftConnection) connect,
  required DriftDialect dialect,
  required String name,
}) {
  return Isolate.run(() async {
    final database = connect(
      DriftConnection.withImplementation(
        dialect: dialect,
        implementation: () async {
          final pool = SqliteConnectionPool.open(
            name: name,
            openConnections: () => throw StateError(
              'Pool should still be open for original database',
            ),
          );

          return OpenedDriftConnection(
            SqlitePoolSession(
              pool,
              // Don't try to re-run migrations here, the database is already
              // open.
              includePersistentSchemaVersion: false,
            ),
            SqlitePoolUpdates(pool, enableCustomUpdates: false),
          );
        },
      ),
    );
    try {
      return await computation(database);
    } finally {
      await database.close();
    }
  });
}
