/// A drift database implementation built on `package:sqlite3/`.
///
/// The [NativeDatabase] class uses `dart:ffi` to access `sqlite3` APIs.
///
/// When using a [NativeDatabase], you need to ensure that `sqlite3` is
/// available when running your app. For mobile Flutter apps, you can simply
/// depend on the `sqlite3_flutter_libs` package to ship the latest sqlite3
/// version with your app.
/// For more information other platforms, see [other engines](https://drift.simonbinder.eu/docs/other-engines/vm/).
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../dialect/sqlite.dart';
import '../../src/connections/connection.dart';
import '../../src/connections/connection_pool.dart';
import '../../src/query_builder.dart';
import '../isolate.dart';
import 'sqlite3.dart';

/// Signature of a function that can perform setup work on a [database] before
/// drift is fully ready.
///
/// This could be used to, for instance, set encryption keys for SQLCipher
/// implementations.
typedef DatabaseSetup = void Function(Database database);

/// Signature of a function that can perform setup work on the isolate before
/// opening the database.
///
/// This could be used to override libraries.
/// For example:
/// ```
/// open.overrideFor(OperatingSystem.android, openCipherOnAndroid)
/// ```
typedef IsolateSetup = FutureOr<void> Function();

/// Signature of a function that obtains an instance of [Sqlite3] bindings.
///
/// By default, drift will use the default [sqlite3] instance from
/// `package:sqlite3`. But especially for users interested in trying out
/// [`sqlite3_native_assets`](https://pub.dev/packages/sqlite3_native_assets),
/// passing this function allows customizing the SQLite bindings:
///
/// ```dart
/// NativeDatabase.createInBackground(
///   File(...),
///   sqlite3: () => sqlite3Native,
/// );
/// ```

typedef SqliteResolver = FutureOr<Sqlite3> Function();

/// A drift database implementation based on `dart:ffi`, running directly in a
/// Dart VM or an AOT compiled Dart/Flutter application.
final class NativeDatabase {
  // when changing this, also update the documentation in `drift_vm_database_factory`.
  static const _cacheStatementsByDefault = true;
  static const _defaultReadPoolSize = 0;

  NativeDatabase(File file);

  /// Creates a database that will store its result in the [file], creating it
  /// if it doesn't exist.
  ///
  /// {@template drift_vm_database_factory}
  /// The [cachePreparedStatements] flag (defaults to `true`) controls whether
  /// drift will cache prepared statement objects, which improves performance as
  /// sqlite3 doesn't have to parse statements that are frequently used multiple
  /// times.
  ///
  /// The optional [setup] function can be used to perform a setup just after
  /// the database is opened, before drift is fully ready. This can be used to
  /// add custom user-defined sql functions or to provide encryption keys in
  /// SQLCipher implementations.
  /// {@endtemplate}
  static DriftConnection blocking(
    File file, {
    SqliteResolver sqlite3 = _defaultResolver,
    DriftDialect dialect = const SqliteDialect(),
    DatabaseSetup? setup,
    bool cachePreparedStatements = _cacheStatementsByDefault,
  }) {
    return DriftConnection(
      dialect: dialect,
      openConnection: () async {
        return SqliteConnection(
          await _openDatabase(
            path: file.path,
            sqlite3: sqlite3,
            setup: setup,
          ),
          cachePreparedStatements: cachePreparedStatements,
        );
      },
    );
  }

  static DriftConnection memory({
    DriftDialect dialect = const SqliteDialect(),
    SqliteResolver sqlite3 = _defaultResolver,
    DatabaseSetup? setup,
    bool cachePreparedStatements = _cacheStatementsByDefault,
  }) {
    return DriftConnection(
      dialect: dialect,
      openConnection: () async {
        return SqliteConnection(
          await _openDatabase(
            path: null,
            sqlite3: sqlite3,
            setup: setup,
          ),
          cachePreparedStatements: cachePreparedStatements,
        );
      },
    );
  }

  /// Creates a drift executor for an opened [database] from the `sqlite3`
  /// package.
  ///
  /// When the [closeUnderlyingOnClose] argument is set (which is the default),
  /// calling [DriftSession.close] on the returned [NativeDatabase] will also
  /// [Database.dispose] the [database] passed to this constructor.
  ///
  /// Using [NativeDatabase.opened] may be useful when you want to use the same
  /// underlying [Database] in multiple drift connections. Drift uses this
  /// internally when running [integration tests for migrations](https://drift.simonbinder.eu/docs/advanced-features/migrations/#verifying-migrations).
  ///
  /// {@macro drift_vm_database_factory}
  static DriftConnection opened(
    Database database, {
    DriftDialect dialect = const SqliteDialect(),
    DatabaseSetup? setup,
    bool closeUnderlyingOnClose = true,
    bool cachePreparedStatements = _cacheStatementsByDefault,
  }) {
    return DriftConnection(
      dialect: dialect,
      openConnection: () async {
        return SqliteConnection(
          database,
          cachePreparedStatements: cachePreparedStatements,
          closeUnderlyingWhenClosed: closeUnderlyingOnClose,
        );
      },
    );
  }

  /// Creates a database storing its result in [file].
  ///
  /// This method will create the same database as the default constructor of
  /// the [NativeDatabase] class. It also behaves the same otherwise: The [file]
  /// is created if it doesn't exist, [logStatements] can be used to print
  /// statements and [setup] can be used to perform a one-time setup work when
  /// the database is created.
  ///
  /// The big distinction of this method is that the database is implicitly
  /// created on a background isolate, freeing up your main thread accessing the
  /// database from I/O work needed to run statements.
  /// When the database returned by this method is closed, the background
  /// isolate will shut down as well.
  ///
  /// When [readPool] is set to a number greater than zero, drift will spawn an
  /// additional number of isolates only responsible for running read operations
  /// (i.e. `SELECT` statements) on the database.
  /// Since the original isolate is used for writes, this causes `readPool + 1`
  /// isolates to be spawned. While these isolates will only run statements on
  /// demand and consume few resources otherwise, using a read pool is not
  /// necessary for most applications. It can make sense to reduce load times in
  /// applications issuing lots of reads at startup, especially if some of these
  /// are known to be slow.
  /// __Please note that [readPool] is only effective when enabling write-ahead
  /// logging!__ In the default journaling mode used by sqlite3, concurrent
  /// reads and writes are forbidden. To enable write-ahead logging, issue a
  /// call to [Database.execute] setting `pragma journal_mode = WAL;` in
  /// [setup].
  ///
  /// The [sqlite3] parameter can be used to provide a function responsible for
  /// obtaining an instance of the [Sqlite3] bindings drift will use to open the
  /// database. This is particularly relevant for users interested in using
  /// drift with the native assets SDK feature, see [SqliteResolver] for an
  /// example.
  ///
  /// Be aware that the functions [setup], [isolateSetup] and [sqlite3], are
  /// sent to other isolates and are executed there. Thus, they don't have
  /// access to the same contents of global variables. Care must also be taken
  /// to ensure that the functions don't capture state not meant to be sent
  /// across isolates.
  static DriftConnection createInBackground(
    File file, {
    DriftDialect dialect = const SqliteDialect(),
    DatabaseSetup? setup,
    SqliteResolver sqlite3 = _defaultResolver,
    IsolateSetup? isolateSetup,
    bool enableMigrations = true,
    bool cachePreparedStatements = _cacheStatementsByDefault,
    int readPool = _defaultReadPoolSize,
  }) {
    RangeError.checkNotNegative(readPool);

    return DriftConnection.withImplementation(
      dialect: dialect,
      implementation: () async {
        final receiveIsolate = ReceivePort();
        final receive = StreamQueue(receiveIsolate.cast<DriftIsolate>());

        Future<void> spawnIsolate(String kind) async {
          await Isolate.spawn(
            _NativeIsolateStartup.start,
            _NativeIsolateStartup(
              file.absolute.path,
              cachePreparedStatements,
              enableMigrations,
              setup,
              isolateSetup,
              sqlite3,
              receiveIsolate.sendPort,
            ),
            debugName: 'Drift isolate $kind for ${file.path}',
          );
        }

        await spawnIsolate('worker');
        final driftIsolate = await receive.next;

        var (session, streams) =
            await driftIsolate.connect(singleClientMode: true);

        if (readPool != 0) {
          final readers = <DriftSession>[];

          for (var i = 0; i < readPool; i++) {
            await spawnIsolate('reader');
          }

          for (var i = 0; i < readPool; i++) {
            final spawned = await receive.next;

            readers.add((await spawned.connect(singleClientMode: true)).$1);
          }

          session = DriftSessionPool(
            write: session,
            reads: readers,
          );
        }

        await receive.cancel();
        receiveIsolate.close();
        return (session, streams);
      },
    );
  }

  static Future<Database> _openDatabase({
    required String? path,
    required SqliteResolver sqlite3,
    required DatabaseSetup? setup,
  }) async {
    final sqlite = await sqlite3();

    Database db;

    if (path != null) {
      final file = File(path);
      // Create the parent directory if it doesn't exist. sqlite will emit
      // confusing misuse warnings otherwise
      final dir = file.parent;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      db = sqlite.open(file.path);
    } else {
      db = sqlite.openInMemory();
    }

    setup?.call(db);
    return db;
  }

  static Sqlite3 _defaultResolver() => sqlite3;
}

class _NativeIsolateStartup {
  final String path;
  final bool enableLogs;
  final bool cachePreparedStatements;
  final DatabaseSetup? setup;
  final IsolateSetup? isolateSetup;
  final SqliteResolver sqlite3;
  final SendPort sendServer;

  _NativeIsolateStartup(
    this.path,
    this.enableLogs,
    this.cachePreparedStatements,
    this.setup,
    this.isolateSetup,
    this.sqlite3,
    this.sendServer,
  );

  static Future<void> start(_NativeIsolateStartup startup) async {
    await startup.isolateSetup?.call();
    final isolate = DriftIsolate.inCurrent(() async {
      return SqliteConnection(
        await NativeDatabase._openDatabase(
          path: startup.path,
          sqlite3: startup.sqlite3,
          setup: startup.setup,
        ),
        cachePreparedStatements: startup.cachePreparedStatements,
      );
    });

    startup.sendServer.send(isolate);
  }
}
