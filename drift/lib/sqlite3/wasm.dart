/// Web support for drift.
///
/// For more information about the components of this library and how to use
/// them, see https://drift.simonbinder.eu/web/.
/// Be aware that additional setup is necessary to use drift on the web, this
/// is explained in the documentation.
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:drift/src/sqlite3/wasm/setup/shared_worker.dart';
import 'package:sqlite3/wasm.dart';
import 'package:web/web.dart'
    show DedicatedWorkerGlobalScope, SharedWorkerGlobalScope;

import '../connections/sqlite/sqlite3.dart';
import '../src/connections/connection.dart';
import '../src/sqlite3/wasm/setup/dedicated_worker.dart';
import '../src/sqlite3/wasm/setup/types.dart';
import '../src/sqlite3/wasm/wasm_setup.dart';

export '../src/sqlite3/wasm/setup/types.dart';

/// Signature of a function that can perform setup work on a [database] before
/// drift is fully ready.
///
/// This could be used to, for instance, set encryption keys for SQLCipher
/// implementations.
typedef DatabaseSetup = void Function(CommonDatabase database);

/// A WebAssembly based implementation of a drift sqlite3 database.
///
/// Using this database requires adding a WebAssembly file for sqlite3 to your
/// app.
/// The [documentation](https://drift.simonbinder.eu/web/#drift-wasm) describes
/// how to obtain this file. A [working example](https://github.com/simolus3/drift/blob/04539882330d80519128fec1ceb120fb1623a831/examples/app/lib/database/connection/web.dart#L27-L36)
/// is also available in the drift repository.
final class WasmDatabase {
  /// Creates a wasm database at [path] in the default virtual file system of
  /// the [sqlite3] module.
  /// If [fileSystem] provided, the data is guaranteed to be
  /// stored in the IndexedDB when the request is complete. Attention!
  /// Insert/update queries may be slower when this option enabled. If you want
  /// to insert more than one rows, be sure you run in a transaction if
  /// possible.
  static DriftSession inCurrentContext({
    required CommonSqlite3 sqlite3,
    required String path,
    WasmDatabaseSetup? setup,
    IndexedDbFileSystem? fileSystem,
    bool cachePreparedStatements = true,
  }) {
    return SqliteConnection(
      _open(sqlite3: sqlite3, path: path, setup: setup),
      cachePreparedStatements: cachePreparedStatements,
    );
  }

  /// Creates an in-memory database in the loaded [sqlite3] database.
  ///
  /// If an in-memory database is all you need, it can be created more easily
  /// than going through the path with [open]. In particular, you probably don't
  /// need a web worker hosting the database.
  ///
  /// To create an in-memory database without workers, one can use:
  ///
  /// ```dart
  /// final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('/sqlite3.wasm'));
  /// sqlite3.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
  ///
  /// WasmDatabase.inMemory(sqlite3);
  /// ```
  static DriftSession inMemory(
    CommonSqlite3 sqlite3, {
    WasmDatabaseSetup? setup,
    bool cachePreparedStatements = true,
  }) {
    return SqliteConnection(
      _open(sqlite3: sqlite3, path: null, setup: setup),
      cachePreparedStatements: cachePreparedStatements,
    );
  }

  /// Creates a drift executor for an opened [database] from the `sqlite3`
  /// package.
  ///
  /// When the [closeUnderlyingOnClose] argument is set (which is the default),
  /// calling [DriftSession.close] on the returned [WasmDatabase] will also
  /// [CommonDatabase.dispose] the [database] passed to this constructor.
  ///
  /// Using [WasmDatabase.opened] may be useful when you want to use the same
  /// underlying [CommonDatabase] in multiple drift connections. Drift uses this
  /// internally when running [integration tests for migrations](https://drift.simonbinder.eu/docs/advanced-features/migrations/#verifying-migrations).
  static DriftSession opened(
    CommonDatabase database, {
    bool closeUnderlyingOnClose = true,
    bool cachePreparedStatements = true,
  }) {
    return SqliteConnection(
      database,
      cachePreparedStatements: cachePreparedStatements,
      closeUnderlyingWhenClosed: closeUnderlyingOnClose,
    );
  }

  /// Opens a database on the web.
  ///
  /// Drift will detect features supported by the current browser and picks an
  /// appropriate implementation to store data based on those results.
  ///
  /// Using this API requires two additional file that you need to copy into the
  /// `web/` folder of your Flutter or Dart application: A `sqlite3.wasm` file,
  /// which you can [get here](https://github.com/simolus3/sqlite3.dart/releases),
  /// and a drift worker, which you can [get here](https://drift.simonbinder.eu/web/#worker).
  ///
  /// [localSetup] will be called to initialize the database only if the
  /// database will be opened directly in this JavaScript context. It is likely
  /// that the database will actually be opened in a web worker, with drift
  /// using communication mechanisms to access the database. As there is no way
  /// to send the database over to the main context, [localSetup] would not be
  /// called in that case. Instead, you'd have to compile a custom drift worker
  /// with a setup function - see [workerMainForOpen] for additional information.
  ///
  /// For more detailed information, see https://drift.simonbinder.eu/web.
  static Future<WasmDatabaseResult> open({
    required String databaseName,
    required Uri sqlite3Uri,
    required Uri driftWorkerUri,
    FutureOr<Uint8List?> Function()? initializeDatabase,
    WasmDatabaseSetup? localSetup,
  }) async {
    final probed = await probe(
      sqlite3Uri: sqlite3Uri,
      driftWorkerUri: driftWorkerUri,
      databaseName: databaseName,
    );

    // If we have an existing database in storage, we want to keep using that
    // format to avoid data loss (e.g. after a browser update that enables a
    // otherwise preferred storage implementation). In the future, we might want
    // to consider migrating between storage implementations as well.
    final availableImplementations = probed.availableStorages.toList();

    checkExisting:
    for (final (location, name) in probed.existingDatabases) {
      if (name == databaseName) {
        final implementationsForStorage = switch (location) {
          WebStorageApi.indexedDb => const [
              WasmStorageImplementation.sharedIndexedDb,
              WasmStorageImplementation.unsafeIndexedDb
            ],
          WebStorageApi.opfs => const [
              WasmStorageImplementation.opfsShared,
              WasmStorageImplementation.opfsLocks,
            ],
        };

        // If any of the implementations for this location is still availalable,
        // we want to use it instead of another location.
        if (implementationsForStorage.any(availableImplementations.contains)) {
          availableImplementations
              .removeWhere((i) => !implementationsForStorage.contains(i));
          break checkExisting;
        }
      }
    }

    // Enum values are ordered by preferrability, so just pick the best option
    // left.
    availableImplementations.sortBy<num>((element) => element.index);

    final bestImplementation = availableImplementations.firstOrNull ??
        WasmStorageImplementation.inMemory;
    final connection = await probed.open(
      bestImplementation,
      databaseName,
      localSetup: localSetup,
      initializeDatabase: initializeDatabase,
    );

    return WasmDatabaseResult(
        connection, bestImplementation, probed.missingFeatures);
  }

  /// Probes for:
  ///
  /// - available storage implementations based on supported web APIs.
  /// - APIs not currently supported by the browser.
  /// - existing drift databases in the current browsing context.
  ///
  /// This information can be used to control whether to open a drift database,
  /// or whether the current browser is unsuitable for the persistence
  /// requirements of your app.
  /// For most apps, using [open] directly is easier. It calls [probe]
  /// internally and uses the best storage implementation available.
  ///
  /// The [databaseName] option is not strictly required. But drift can't list
  /// databases stored in IndexedDb, they are not part of
  /// [WasmProbeResult.existingDatabases] by default. This is because drift
  /// databases can't be distinguished from other IndexedDb databases without
  /// opening them, which might disturb the running operation of them. When a
  /// [databaseName] is passed, drift will explicitly probe whether a database
  /// with that name exists in IndexedDb and whether it is a drift database.
  /// Drift is always able to list databases stored in OPFS, regardless of
  /// whether [databaseName] is passed or not.
  ///
  /// Note that this method is only fully supported when using the drift worker
  /// shipped with the drift 2.11 release. Older workers are only supported when
  /// [databaseName] is non-null.
  static Future<WasmProbeResult> probe({
    required Uri sqlite3Uri,
    required Uri driftWorkerUri,
    String? databaseName,
  }) async {
    return await WasmDatabaseOpener(sqlite3Uri, driftWorkerUri, databaseName)
        .probe();
  }

  /// The entrypoint for a web worker suitable for use with [open].
  ///
  /// Generally, you can grab a pre-compiled worker file from a
  /// [drift release](https://github.com/simolus3/drift/releases) and don't need
  /// to call this method in your app.
  ///
  /// If you prefer to compile the worker yourself, write a simple Dart program
  /// that calls this method in its `main()` function and compile that with
  /// `dart2js`.
  /// This is particularly useful when using [setupAllDatabases], a callback
  /// that will be invoked on every new [CommonDatabase] created by the web
  /// worker. This is a suitable place to register custom functions.
  static void workerMainForOpen({
    WasmDatabaseSetup? setupAllDatabases,
  }) {
    final self = globalContext;

    if (self.instanceOfString('DedicatedWorkerGlobalScope')) {
      DedicatedDriftWorker(
              self as DedicatedWorkerGlobalScope, setupAllDatabases)
          .start();
    } else if (self.instanceOfString('SharedWorkerGlobalScope')) {
      SharedDriftWorker(self as SharedWorkerGlobalScope, setupAllDatabases)
          .start();
    }
  }

  static CommonDatabase _open({
    required CommonSqlite3 sqlite3,
    required String? path,
    required WasmDatabaseSetup? setup,
  }) {
    final db = path == null ? sqlite3.openInMemory() : sqlite3.open(path);
    setup?.call(db);
    return db;
  }
}
