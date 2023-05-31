/// An experimental web-compatible version of drift that doesn't depend
/// on external JavaScript sources.
///
/// While the implementation is tested and no API breaking changes are expected
/// to the public interface, it is still fairly new and may have remaining bugs
/// or issues.
///
/// A generally less efficient, but currently more stable backend is available
/// through the `package:drift/web.dart` library described in the
/// [documentation][https://drift.simonbinder.eu/web/].
@experimental
library drift.wasm;

import 'dart:html';

import 'package:meta/meta.dart';
import 'package:sqlite3/wasm.dart';

import 'backends.dart';
import 'drift.dart';
import 'src/sqlite3/database.dart';
import 'src/web/wasm_setup.dart';
import 'src/web/wasm_setup/dedicated_worker.dart';
import 'src/web/wasm_setup/shared_worker.dart';

/// Signature of a function that can perform setup work on a [database] before
/// drift is fully ready.
///
/// This could be used to, for instance, set encryption keys for SQLCipher
/// implementations.
typedef WasmDatabaseSetup = void Function(CommonDatabase database);

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
  }) {
    return WasmDatabase._(
        _WasmDelegate(sqlite3, path, setup, fileSystem), logStatements);
  }

  /// Creates an in-memory database in the loaded [sqlite3] database.
  factory WasmDatabase.inMemory(
    CommonSqlite3 sqlite3, {
    WasmDatabaseSetup? setup,
    bool logStatements = false,
  }) {
    return WasmDatabase._(
        _WasmDelegate(sqlite3, null, setup, null), logStatements);
  }

  static Future<WasmDatabaseResult> open({
    required String databaseName,
    required Uri sqlite3Uri,
    required Uri driftWorkerUri,
  }) {
    return openWasmDatabase(
      databaseName: databaseName,
      sqlite3WasmUri: sqlite3Uri,
      driftWorkerUri: driftWorkerUri,
    );
  }

  static void workerMainForOpen() {
    final self = WorkerGlobalScope.instance;

    if (self is DedicatedWorkerGlobalScope) {
      DedicatedDriftWorker(self).start();
    } else if (self is SharedWorkerGlobalScope) {
      SharedDriftWorker(self).start();
    }
  }
}

class _WasmDelegate extends Sqlite3Delegate<CommonDatabase> {
  final CommonSqlite3 _sqlite3;
  final String? _path;
  final IndexedDbFileSystem? _fileSystem;

  _WasmDelegate(
      this._sqlite3, this._path, WasmDatabaseSetup? setup, this._fileSystem)
      : super(setup);

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
    if (closeUnderlyingWhenClosed) {
      database.dispose();
      await _flush();
    }
  }
}

/// The storage implementation used by the `drift` and `sqlite3` packages to
/// emulate a synchronous file system on the web, used by the sqlite3 C library
/// to store databases.
///
/// As persistence APIs exposed by Browsers are usually asynchronous, faking
/// a synchronous file system
enum WasmStorageImplementation {
  /// Uses the [Origin private file system APIs][OPFS] provided my modern
  /// browsers to persist data.
  ///
  /// In this storage mode, drift will host a single shared worker between tabs.
  /// As the file system API is only available in dedicated workers, the shared
  /// worker will spawn an internal dedicated worker which is thus shared between
  /// tabs as well.
  ///
  /// The OPFS API allows synchronous access to files, but only after they have
  /// been opened asynchronously. Since sqlite3 only needs access to two files
  /// for a database files, we can just open them once and keep them open while
  /// the database is in use.
  ///
  /// This mode is a very reliable and efficient approach to access sqlite3
  /// on the web, and the preferred mode used by drift.
  ///
  /// While the relevant specifications allow shared workers to spawn nested
  /// workers, this is only implemented in Firefox at the time of writing.
  /// Chrome (https://crbug.com/1088481) and Safari don't support this yet.
  ///
  /// [OPFS]: https://developer.mozilla.org/en-US/docs/Web/API/File_System_Access_API#origin_private_file_system
  opfsShared,

  /// Uses the [Origin private file system APIs][OPFS] provided my modern
  /// browsers to persist data.
  ///
  /// Unlike [opfsShared], this storage implementation does not use a shared
  /// worker (either because it is not available or because the current browser
  /// doesn't allow shared workers to spawn dedicated workers). Instead, each
  /// tab spawns two dedicated workers that use `Atomics.wait` and `Atomics.notify`
  /// to turn the asynchronous OPFS API into a synchronous file system
  /// implementation.
  ///
  /// While being less efficient than [opfsShared], this mode is also very
  /// reliably and used by the official WASM builds of the sqlite3 project as
  /// well.
  ///
  /// It requires [cross-origin isolation], which needs to be enabled by serving
  /// your app with special headers:
  ///
  /// ```
  /// Cross-Origin-Opener-Policy: same-origin
  /// Cross-Origin-Embedder-Policy: require-corp
  /// ```
  ///
  /// [OPFS]: https://developer.mozilla.org/en-US/docs/Web/API/File_System_Access_API#origin_private_file_system´
  /// [cross-origin isolation]: https://developer.mozilla.org/en-US/docs/Web/API/crossOriginIsolated
  opfsLocks,

  sharedIndexedDb,

  /// Uses the asynchronous IndexedDB API outside of any worker to persist data.
  ///
  /// Unlike [opfsShared] or [opfsLocks], this storage implementation can't
  /// prevent two tabs from accessing the same data.
  unsafeIndexedDb,

  /// A fallback storage implementation that doesn't store anything.
  ///
  /// This implementation is chosen when none of the features needed for other
  /// storage implementations are supported by the current browser. In this case,
  /// [WasmDatabaseResult.missingFeatures] enumerates missing browser features.
  inMemory,
}

enum MissingBrowserFeature {
  sharedWorkers,
  dedicatedWorkersInSharedWorkers,
  nestedDedicatedWorkers,
  fileSystemAccess,
  indexedDb,
  sharedArrayBuffers,
  notCrossOriginIsolated,
}

class WasmDatabaseResult {
  final DatabaseConnection resolvedExecutor;
  final WasmStorageImplementation chosenImplementation;
  final Set<MissingBrowserFeature> missingFeatures;

  WasmDatabaseResult(
      this.resolvedExecutor, this.chosenImplementation, this.missingFeatures);
}
