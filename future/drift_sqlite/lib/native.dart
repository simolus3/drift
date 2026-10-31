/// `drift_sqlite` features that only work on native platforms.
///
/// Importantly, this includes.
library;

import 'dart:io';

import 'package:drift3_preview/drift.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_connection_pool/sqlite3_connection_pool.dart';

import 'src/connection/pool.dart';
import 'src/connection/pool/worker.dart';
import 'src/dialect/dialect.dart';
import 'src/options.dart';

export 'src/options.dart';

/// Opens a pool of SQLite connection for high-performance and concurrent
/// queries.
///
/// This opens a single connnection for writes and additional [amountOfReaders]
/// connections for reads.
/// The [configureDatabase] callback can be used to run custom pragmas on the
/// database. This method will configure the database to run in the `WAL`
/// journal mode.
///
/// The [preparedStatementCacheSize] parameter can be used to configure a cache
/// of prepared statements to avoid compiling the same statements (by their
/// SQL text) frequently. By default, 16 statements are cached per connection in
/// the pool. The value can be set to `0` to disable the statement cache.
///
/// [useBackgroundIsolates] (enabled by default) controls whether queries should
/// run on a background isolate. This should be enabled when this function is
/// called on the main UI isolate to avoid blocking it. For background tasks
/// with database access, disabling it can make queries faster by running them
/// synchronously on the calling thread.
///
/// Two isolates calling [sqliteConnectionPool] with the same path will
/// implicitly use the same connection pool without conflict.
DriftConnection sqliteConnectionPool({
  required File file,
  UpdateNotificationMode updates = .native,
  int amountOfReaders = 4,
  int preparedStatementCacheSize = 16,
  bool useBackgroundIsolates = true,
  void Function(Database, {required bool isWriter})? configureDatabase,
}) {
  final path = file.absolute.path;

  return customConnectionPool(
    identifier: path,
    openPool: () => _sqliteConnectionPool(
      path: path,
      amountOfReaders: amountOfReaders,
      preparedStatementCacheSize: preparedStatementCacheSize,
      useBackgroundIsolates: useBackgroundIsolates,
      configureDatabase: configureDatabase,
      updates: updates,
    ),
    updates: updates,
    workerIsolates: useBackgroundIsolates ? amountOfReaders + 1 : null,
  );
}

/// Opens a custom pool of SQLite connections for high-performance and
/// concurrent queries.
///
/// Most apps would typically use [sqliteConnectionPool], which applies
/// recommended options.
///
/// The [openPool] method is responsible for opening a pool from the
/// `sqlite3_connection_pool` package. Typically, connections are configured
/// with `PRAGMA journal_mode = WAL` to safely allow multiple concurrent
/// readers. The pool must enable native updates when [updates] is set to
/// [UpdateNotificationMode.native] (the default).
///
/// When [workerIsolates] is set to a non-null value, drift will spawn that
/// amount of background isolates to run queries. Additional background isolates
/// may be spawned if needed. When set to null, drift won't spawn background
/// isolates for this connection pool.
///
/// For example, this can be used to configure a single-connection "pool" for an
/// in-memory database:
///
/// ```dart
/// final identifier = 'in-memory';
/// final db = AppDatabase(customConnectionPool(
///   identifier: identifier,
///   openPool:() async {
///     return SqliteConnectionPool.open(
///       name: identifier,
///       openConnections: () => PoolConnections(sqlite3.openInMemory(), []),
///     );
///   },
///   workerIsolates: 1,
/// ));
/// ```
DriftConnection customConnectionPool({
  required String identifier,
  UpdateNotificationMode updates = .native,
  required Future<SqliteConnectionPool> Function() openPool,
  int? workerIsolates,
}) {
  return DriftConnection.withImplementation(
    dialect: SqliteDialect.new,
    implementation: (_) async {
      final pool = await openPool();

      return OpenedDriftConnection(
        SqlitePoolSession(
          pool,
          isolates: workerIsolates != null
              // Capacity is readers plus writer
              ? DatabaseWorkers(identifier, workerIsolates)
              : null,
        ),
        SqlitePoolUpdates(pool, enableCustomUpdates: updates == .drift),
      );
    },
  );
}

Future<SqliteConnectionPool> _sqliteConnectionPool({
  required String path,
  required int amountOfReaders,
  required int preparedStatementCacheSize,
  required bool useBackgroundIsolates,
  required void Function(Database, {required bool isWriter})? configureDatabase,
  required UpdateNotificationMode updates,
}) {
  return SqliteConnectionPool.openAsync(
    name: path,
    openConnections: () {
      void configureConnection(Database db, bool isWriter) {
        configureDatabase?.call(db, isWriter: isWriter);

        if (isWriter) {
          db.execute('PRAGMA journal_mode = WAL;');
        }
      }

      final writer = sqlite3.open(path);
      final readers = <Database>[];
      try {
        configureConnection(writer, true);

        for (var i = 0; i < amountOfReaders; i++) {
          final reader = sqlite3.open(path);
          configureConnection(reader, false);
          readers.add(reader);
        }
      } on Object {
        writer.close();
        for (final reader in readers) {
          reader.close();
        }

        rethrow;
      }

      return PoolConnections(
        writer,
        readers,
        preparedStatementCacheSize: preparedStatementCacheSize,
        enableNativeUpdateHooks: updates == .native,
      );
    },
  );
}
