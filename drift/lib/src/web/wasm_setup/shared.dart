import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';

import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/wasm.dart';
import 'package:js/js_util.dart';
// ignore: implementation_imports
import 'package:sqlite3/src/wasm/js_interop/file_system_access.dart';
import 'package:sqlite3/wasm.dart';

import '../channel.dart';
import 'protocol.dart';

/// Checks whether the OPFS API is likely to be correctly implemented in the
/// current browser.
///
/// Since OPFS uses the synchronous file system access API, this method can only
/// return true when called in a dedicated worker.
Future<bool> checkOpfsSupport() async {
  final storage = storageManager;
  if (storage == null) return false;

  const testFileName = '_drift_feature_detection';

  FileSystemDirectoryHandle? opfsRoot;
  FileSystemFileHandle? fileHandle;
  FileSystemSyncAccessHandle? openedFile;

  try {
    opfsRoot = await storage.directory;

    fileHandle = await opfsRoot.openFile(testFileName, create: true);
    openedFile = await fileHandle.createSyncAccessHandle();

    // In earlier versions of the OPFS standard, some methods like `getSize()`
    // on a sync file handle have actually been asynchronous. We don't support
    // Browsers that implement the outdated spec.
    final getSizeResult = callMethod<Object?>(openedFile, 'getSize', []);
    if (typeofEquals<Object?>(getSizeResult, 'object')) {
      // Returned a promise, that's no good.
      await promiseToFuture<Object?>(getSizeResult!);
      return false;
    }

    return true;
  } on Object {
    return false;
  } finally {
    if (openedFile != null) {
      openedFile.close();
    }

    if (opfsRoot != null && fileHandle != null) {
      await opfsRoot.removeEntry(testFileName);
    }
  }
}

/// Checks whether IndexedDB is working in the current browser.
Future<bool> checkIndexedDbSupport() async {
  if (!hasProperty(globalThis, 'indexedDB') ||
      // FileReader needed to read and write blobs efficiently
      !hasProperty(globalThis, 'FileReader')) {
    return false;
  }

  final idb = getProperty<IdbFactory>(globalThis, 'indexedDB');

  try {
    const name = 'drift_mock_db';

    final mockDb = await idb.open(name);
    mockDb.close();
    idb.deleteDatabase(name);
  } catch (error) {
    return false;
  }

  return true;
}

/// Returns whether an drift-wasm database with the given [databaseName] exists.
Future<bool> checkIndexedDbExists(String databaseName) async {
  bool? indexedDbExists;

  try {
    final idb = getProperty<IdbFactory>(globalThis, 'indexedDB');

    final database = await idb.open(
      databaseName,
      // Current schema version used by the [IndexedDbFileSystem]
      version: 1,
      onUpgradeNeeded: (event) {
        // If there's an upgrade, we're going from 0 to 1 - the database doesn't
        // exist! Abort the transaction so that we don't create it here.
        event.target.transaction!.abort();
        indexedDbExists = false;
      },
    );

    indexedDbExists ??= true;
    database.close();
  } catch (_) {
    // May throw due to us aborting in the upgrade callback.
  }

  return indexedDbExists ?? false;
}

/// Deletes a database from IndexedDb if supported.
Future<void> deleteDatabaseInIndexedDb(String databaseName) async {
  final idb = window.indexedDB;
  if (idb != null) {
    await idb.deleteDatabase(databaseName);
  }
}

/// Constructs the path used by drift to store a database in the origin-private
/// section of the agent's file system.
String pathForOpfs(String databaseName) {
  return 'drift_db/$databaseName';
}

/// Collects all drift OPFS databases.
Future<List<String>> opfsDatabases() async {
  final storage = storageManager;
  if (storage == null) return const [];

  var directory = await storage.directory;
  try {
    directory = await directory.getDirectory('drift_db');
  } on Object {
    // The drift_db folder doesn't exist, so there aren't any databases.
    return const [];
  }

  return [
    await for (final entry in directory.list())
      if (entry.isDirectory) entry.name,
  ];
}

/// Deletes the OPFS folder storing a database with the given [databaseName] if
/// such folder exists.
Future<void> deleteDatabaseInOpfs(String databaseName) async {
  final storage = storageManager;
  if (storage == null) return;

  var directory = await storage.directory;
  try {
    directory = await directory.getDirectory('drift_db');
    await directory.removeEntry(databaseName, recursive: true);
  } on Object {
    // fine, an error probably means that the database didn't exist in the first
    // place.
  }
}

/// Manages drift servers.
///
/// When using a shared worker, multiple clients may want to use different drift
/// databases. This server keeps track of drift servers by their database names
/// to allow that.
class DriftServerController {
  /// Running drift servers by the name of the database they're serving.
  final Map<String, RunningWasmServer> servers = {};
  final WasmDatabaseSetup? _setup;

  /// Creates a controller responsible for loading wasm databases and serving
  /// them. The [_setup] callback will be invoked on created databases if set.
  DriftServerController(this._setup);

  /// Serves a drift connection as requested by the [message].
  void serve(
    ServeDriftDatabase message,
  ) {
    final server = servers.putIfAbsent(message.databaseName, () {
      final initPort = message.initializationPort;

      final initializer = initPort != null
          ? () async {
              initPort.postMessage(true);

              return await initPort.onMessage
                  .map((e) => e.data as Uint8List?)
                  .first;
            }
          : null;

      final server = DriftServer(LazyDatabase(() => openConnection(
            sqlite3WasmUri: message.sqlite3WasmUri,
            databaseName: message.databaseName,
            storage: message.storage,
            initializer: initializer,
          )));

      return RunningWasmServer(message.storage, server);
    });

    server.server.serve(message.port.channel());
  }

  /// Loads a new sqlite3 WASM module, registers an appropriate VFS for [storage]
  /// and finally opens a database, creating it if it doesn't exist.
  Future<WasmDatabase> openConnection({
    required Uri sqlite3WasmUri,
    required String databaseName,
    required WasmStorageImplementation storage,
    required FutureOr<Uint8List?> Function()? initializer,
  }) async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(sqlite3WasmUri);

    final vfs = await switch (storage) {
      WasmStorageImplementation.opfsShared =>
        SimpleOpfsFileSystem.loadFromStorage(pathForOpfs(databaseName)),
      WasmStorageImplementation.opfsLocks => _loadLockedWasmVfs(databaseName),
      WasmStorageImplementation.unsafeIndexedDb ||
      WasmStorageImplementation.sharedIndexedDb =>
        IndexedDbFileSystem.open(dbName: databaseName),
      WasmStorageImplementation.inMemory => Future.value(InMemoryFileSystem()),
    };

    if (initializer != null && vfs.xAccess('/database', 0) == 0) {
      final response = await initializer();

      if (response != null) {
        final (file: file, outFlags: _) =
            vfs.xOpen(Sqlite3Filename('/database'), SqlFlag.SQLITE_OPEN_CREATE);
        file.xWrite(response, 0);
        file.xClose();
      }
    }

    sqlite3.registerVirtualFileSystem(vfs, makeDefault: true);
    return WasmDatabase(sqlite3: sqlite3, path: '/database', setup: _setup);
  }

  Future<WasmVfs> _loadLockedWasmVfs(String databaseName) async {
    // Create SharedArrayBuffers to synchronize requests
    final options = WasmVfs.createOptions(
      root: pathForOpfs(databaseName),
    );
    final worker = Worker(Uri.base.toString());

    StartFileSystemServer(options).sendToWorker(worker);

    // Wait for the server worker to report that it's ready
    await worker.onMessage.first;

    return WasmVfs(workerOptions: options);
  }
}

/// Information about a running drift server in a web worker.
class RunningWasmServer {
  /// The storage implementation used by the VFS of this server.
  final WasmStorageImplementation storage;

  /// The server hosting the drift database.
  final DriftServer server;

  /// Default constructor
  RunningWasmServer(this.storage, this.server);
}

/// Reported compatibility results with IndexedDB and OPFS.
class WasmCompatibility {
  /// Whether IndexedDB is available.
  final bool supportsIndexedDb;

  /// Whether OPFS is available.
  final bool supportsOpfs;

  /// Default constructor
  WasmCompatibility(this.supportsIndexedDb, this.supportsOpfs);
}

/// Internal classification of storage implementations.
extension StorageClassification on WasmStorageImplementation {
  /// Whether this implementation uses the OPFS filesystem API.
  bool get isOpfsBased =>
      this == WasmStorageImplementation.opfsShared ||
      this == WasmStorageImplementation.opfsLocks;

  /// Whether this implementation uses the IndexedDB API.
  bool get isIndexedDbBased =>
      this == WasmStorageImplementation.sharedIndexedDb ||
      this == WasmStorageImplementation.unsafeIndexedDb;
}
