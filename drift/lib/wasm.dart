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

import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/wasm.dart';

import 'backends.dart';
import 'src/sqlite3/database.dart';

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
    required CommmonSqlite3 sqlite3,
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
    CommmonSqlite3 sqlite3, {
    WasmDatabaseSetup? setup,
    bool logStatements = false,
  }) {
    return WasmDatabase._(
        _WasmDelegate(sqlite3, null, setup, null), logStatements);
  }
}

class _WasmDelegate extends Sqlite3Delegate<CommonDatabase> {
  final CommmonSqlite3 _sqlite3;
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

enum WasmStorageImplementation {
  opfsShared,
  opfsLocks,
  unsafeIndexedDb,
  inMemory,
}

enum MissingBrowserFeature {
  sharedWorkers,
  dedicatedWorkersInSharedWorkers,
  nestedDedicatedWorkers,
  fileSystemAccess,
  indexedDb,
  atomics,
  sharedArrayBuffers,
}

class WasmDatabaseResult {
  final QueryExecutor resolvedExecutor;
  final WasmStorageImplementation chosenImplementation;
  final Set<MissingBrowserFeature> missingFeatures;

  WasmDatabaseResult(
      this.resolvedExecutor, this.chosenImplementation, this.missingFeatures);
}
