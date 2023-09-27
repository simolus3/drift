/// Web support for drift.
///
/// For more information about the components of this library and how to use
/// them, see https://drift.simonbinder.eu/web/.
/// Be aware that additional setup is necessary to use drift on the web, this
/// is explained in the documentation.
library drift.wasm;

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:drift/src/web/wasm_setup.dart';
import 'package:sqlite3/wasm.dart';

import 'backends.dart';
import 'src/sqlite3/database.dart';
import 'src/web/wasm_setup/dedicated_worker.dart';
import 'src/web/wasm_setup/shared_worker.dart';
import 'src/web/wasm_setup/types.dart';

export 'src/web/wasm_setup/types.dart';

/// An experimental, WebAssembly based implementation of a drift sqlite3
/// database.
///
/// Using this database requires adding a WebAssembly file for sqlite3 to your
/// app.
/// The [documentation](https://drift.simonbinder.eu/web/#drift-wasm) describes
/// how to obtain this file. A [working example](https://github.com/simolus3/drift/blob/04539882330d80519128fec1ceb120fb1623a831/examples/app/lib/database/connection/web.dart#L27-L36)
/// is also available in the drift repository.
class WasmDatabase extends DelegatedDatabase {
  WasmDatabase._(DatabaseDelegate delegate, bool logStatements)
      : super(delegate, isSequential: true, logStatements: logStatements);

  /// Creates a wasm database at [path] in the virtual file system of the
  /// [sqlite3] module.
  /// If [fileSystem] provided, the data is guaranteed to be
  /// stored in the IndexedDB when the request is complete. Attention!
  /// Insert/update queries may be slower when this option enabled. If you want
  /// to insert more than one rows, be sure you run in a transaction if
  /// possible.
  factory WasmDatabase({
    required CommonSqlite3 sqlite3,
    required String path,
    WasmDatabaseSetup? setup,
    IndexedDbFileSystem? fileSystem,
    bool logStatements = false,
    bool cachePreparedStatements = true,
  }) {
    return WasmDatabase._(
      _WasmDelegate(sqlite3, path, setup, fileSystem, cachePreparedStatements),
      logStatements,
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
  factory WasmDatabase.inMemory(
    CommonSqlite3 sqlite3, {
    WasmDatabaseSetup? setup,
    bool logStatements = false,
    bool cachePreparedStatements = true,
  }) {
    return WasmDatabase._(
      _WasmDelegate(sqlite3, null, setup, null, cachePreparedStatements),
      logStatements,
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
    final connection = await probed.open(bestImplementation, databaseName,
        localSetup: localSetup);

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
    final self = WorkerGlobalScope.instance;

    if (self is DedicatedWorkerGlobalScope) {
      DedicatedDriftWorker(self, setupAllDatabases).start();
    } else if (self is SharedWorkerGlobalScope) {
      SharedDriftWorker(self, setupAllDatabases).start();
    }
  }
}

class _WasmDelegate extends Sqlite3Delegate<CommonDatabase> {
  final CommonSqlite3 _sqlite3;
  final String? _path;
  final IndexedDbFileSystem? _fileSystem;

  _WasmDelegate(
    this._sqlite3,
    this._path,
    WasmDatabaseSetup? setup,
    this._fileSystem,
    bool cachePreparedStatements,
  ) : super(
          setup,
          cachePreparedStatements: cachePreparedStatements,
        );

  @override
  CommonDatabase openDatabase() {
    final path = _path;
    if (path == null) {
      return _sqlite3.openInMemory();
    } else {
      return _sqlite3.open(path);
    }
  }

  Future<void> _flush() async {
    await _fileSystem?.flush();
  }

  Future _runWithArgs(String statement, List<Object?> args) async {
    runWithArgsSync(statement, args);

    if (!isInTransaction) {
      await _flush();
    }
  }

  @override
  Future<void> runCustom(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
    return database.lastInsertRowId;
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
    return database.getUpdatedRows();
  }

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    runBatchSync(statements);

    if (!isInTransaction) {
      await _flush();
    }
  }

  @override
  Future<void> close() async {
    await super.close();

    if (closeUnderlyingWhenClosed) {
      database.dispose();
      await _flush();
    }
  }
}
