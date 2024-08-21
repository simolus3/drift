import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/wasm.dart';
import 'package:web/web.dart'
    show
        Worker,
        Navigator,
        StorageManager,
        IDBFactory,
        IDBRequest,
        IDBDatabase,
        IDBVersionChangeEvent,
        EventStreamProviders,
        MessageEvent,
        FileSystemDirectoryHandle,
        FileSystemFileHandle,
        FileSystemHandle,
        FileSystemSyncAccessHandle,
        FileSystemGetFileOptions,
        FileSystemRemoveOptions;
// ignore: implementation_imports
import 'package:sqlite3/src/wasm/js_interop/core.dart';
import 'package:sqlite3/wasm.dart';
import 'package:stream_channel/stream_channel.dart';

import '../channel_new.dart';
import 'protocol.dart';

@JS('navigator')
external Navigator get _navigator;

StorageManager? get _storageManager {
  final navigator = _navigator;

  if (navigator.has('storage')) {
    return navigator.storage;
  }

  return null;
}

/// Checks whether the OPFS API is likely to be correctly implemented in the
/// current browser.
///
/// Since OPFS uses the synchronous file system access API, this method can only
/// return true when called in a dedicated worker.
Future<bool> checkOpfsSupport() async {
  final storage = _storageManager;
  if (storage == null) return false;

  const testFileName = '_drift_feature_detection';

  FileSystemDirectoryHandle? opfsRoot;
  FileSystemFileHandle? fileHandle;
  FileSystemSyncAccessHandle? openedFile;

  try {
    opfsRoot = await storage.getDirectory().toDart;

    fileHandle = await opfsRoot
        .getFileHandle(testFileName, FileSystemGetFileOptions(create: true))
        .toDart;
    openedFile = await fileHandle.createSyncAccessHandle().toDart;

    // In earlier versions of the OPFS standard, some methods like `getSize()`
    // on a sync file handle have actually been asynchronous. We don't support
    // Browsers that implement the outdated spec.
    final getSizeResult = (openedFile as JSObject).callMethod('getSize'.toJS);
    if (getSizeResult.typeofEquals('object')) {
      // Returned a promise, that's no good.
      await (getSizeResult as JSPromise).toDart;
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
      await opfsRoot.removeEntry(testFileName).toDart;
    }
  }
}

/// Checks whether IndexedDB is working in the current browser.
Future<bool> checkIndexedDbSupport() async {
  if (!globalContext.has('indexedDB') ||
      // FileReader needed to read and write blobs efficiently
      !globalContext.has('FileReader')) {
    return false;
  }

  final idb = globalContext['indexedDB'] as IDBFactory;

  try {
    const name = 'drift_mock_db';

    final mockDb = await idb.open(name).complete<IDBDatabase>();
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
    final idb = globalContext['indexedDB'] as IDBFactory;

    // Instead of the open+abort hack below, see if we can use a newer web API
    // listing databases instead.
    if (idb.has('databases')) {
      final databases = await idb.databases().toDart;
      for (final entry in databases.toDart) {
        if (entry.name == databaseName) {
          return true;
        }
      }

      return false;
    }

    final openRequest = idb.open(databaseName, 1);
    openRequest.onupgradeneeded = (IDBVersionChangeEvent event) {
      // If there's an upgrade, we're going from 0 to 1 - the database doesn't
      // exist! Abort the transaction so that we don't create it here.
      openRequest.transaction!.abort();
      indexedDbExists = false;
    }.toJS;
    final database = await openRequest.complete<IDBDatabase>();

    indexedDbExists ??= true;
    database.close();

    if (indexedDbExists == false) {
      // We've just created the database in onUpgradeNeeded. We tried to abort
      // that, but it looks like Safari does the worst possible thing then and
      // keeps an empty database with an initialized version around.
      await idb.deleteDatabase(databaseName).complete();
    }
  } catch (_) {
    // May throw due to us aborting in the upgrade callback.
  }

  return indexedDbExists ?? false;
}

/// Deletes a database from IndexedDb if supported.
Future<void> deleteDatabaseInIndexedDb(String databaseName) async {
  if (globalContext.has('indexedDB')) {
    final idb = globalContext['indexedDB'] as IDBFactory;
    await idb.deleteDatabase(databaseName).complete<JSAny?>();
  }
}

/// Constructs the path used by drift to store a database in the origin-private
/// section of the agent's file system.
String pathForOpfs(String databaseName) {
  return 'drift_db/$databaseName';
}

/// Collects all drift OPFS databases.
Future<List<String>> opfsDatabases() async {
  final storage = _storageManager;
  if (storage == null) return const [];

  var directory = await storage.getDirectory().toDart;
  try {
    directory = await directory.getDirectoryHandle('drift_db').toDart;
  } on Object {
    // The drift_db folder doesn't exist, so there aren't any databases.
    return const [];
  }

  final entries = AsyncJavaScriptIteratable<JSArray>(directory)
      .map((data) => data.toDart[1] as FileSystemHandle);

  return [
    await for (final entry in entries)
      if (entry.kind == 'directory') entry.name,
  ];
}

/// Deletes the OPFS folder storing a database with the given [databaseName] if
/// such folder exists.
Future<void> deleteDatabaseInOpfs(String databaseName) async {
  final storage = _storageManager;
  if (storage == null) return;

  var directory = await storage.getDirectory().toDart;
  try {
    directory = await directory.getDirectoryHandle('drift_db').toDart;
    await directory
        .removeEntry(databaseName, FileSystemRemoveOptions(recursive: true))
        .toDart;
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
          ? () {
              final completer = Completer<Uint8List?>();
              initPort.postMessage(true.toJS);

              initPort.onmessage = (MessageEvent e) {
                final data = (e.data as JSUint8Array?);
                completer.complete(data?.toDart);
              }.toJS;

              return completer.future;
            }
          : null;

      final server = DriftServer(LazyDatabase(() => openConnection(
            sqlite3WasmUri: message.sqlite3WasmUri,
            databaseName: message.databaseName,
            storage: message.storage,
            initializer: initializer,
            enableMigrations: message.enableMigrations,
          )));

      final wasmServer = RunningWasmServer(message.storage, server);
      wasmServer.lastClientDisconnected.whenComplete(() {
        servers.remove(message.databaseName);
        wasmServer.server.shutdown();
      });
      return wasmServer;
    });

    server.serve(message.port
        .channel(explicitClose: message.protocolVersion >= ProtocolVersion.v1));
  }

  /// Loads a new sqlite3 WASM module, registers an appropriate VFS for [storage]
  /// and finally opens a database, creating it if it doesn't exist.
  Future<QueryExecutor> openConnection({
    required Uri sqlite3WasmUri,
    required String databaseName,
    required WasmStorageImplementation storage,
    required FutureOr<Uint8List?> Function()? initializer,
    required bool enableMigrations,
  }) async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(sqlite3WasmUri);

    VirtualFileSystem vfs;
    void Function()? close;

    switch (storage) {
      case WasmStorageImplementation.opfsShared:
        final simple = vfs = await SimpleOpfsFileSystem.loadFromStorage(
            pathForOpfs(databaseName));
        close = simple.close;
      case WasmStorageImplementation.opfsLocks:
        final locks = vfs = await _loadLockedWasmVfs(databaseName);
        close = locks.close;
      case WasmStorageImplementation.unsafeIndexedDb:
      case WasmStorageImplementation.sharedIndexedDb:
        final idb = vfs = await IndexedDbFileSystem.open(dbName: databaseName);
        close = idb.close;
      case WasmStorageImplementation.inMemory:
        vfs = InMemoryFileSystem();
    }

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
    var db = WasmDatabase(
      sqlite3: sqlite3,
      path: '/database',
      setup: _setup,
      enableMigrations: enableMigrations,
    );

    if (close != null) {
      return db.interceptWith(_CloseVfsOnClose(db, close));
    } else {
      return db;
    }
  }

  Future<WasmVfs> _loadLockedWasmVfs(String databaseName) async {
    // Create SharedArrayBuffers to synchronize requests
    final options = WasmVfs.createOptions(
      root: pathForOpfs(databaseName),
    );
    final worker = Worker(Uri.base.toString().toJS);

    StartFileSystemServer(options).sendToWorker(worker);

    // Wait for the server worker to report that it's ready
    await EventStreamProviders.messageEvent.forTarget(worker).first;

    return WasmVfs(workerOptions: options);
  }
}

class _CloseVfsOnClose extends QueryInterceptor {
  final FutureOr<void> Function() _close;
  final QueryExecutor _root;

  _CloseVfsOnClose(this._root, this._close);

  @override
  Future<void> close(QueryExecutor inner) async {
    await inner.close();
    if (identical(_root, inner)) {
      await _close();
    }
  }
}

/// Information about a running drift server in a web worker.
class RunningWasmServer {
  /// The storage implementation used by the VFS of this server.
  final WasmStorageImplementation storage;

  /// The server hosting the drift database.
  final DriftServer server;

  int _connectedClients = 0;
  final Completer<void> _lastClientDisconnected = Completer.sync();

  /// A future that completes synchronously after all [serve]d connections have
  /// closed.
  Future<void> get lastClientDisconnected => _lastClientDisconnected.future;

  /// Default constructor
  RunningWasmServer(this.storage, this.server);

  /// Tracks a new connection and serves drift database requests over it.
  void serve(StreamChannel<Object?> channel) {
    _connectedClients++;

    server.serve(
      channel.transformStream(StreamTransformer.fromHandlers(
        handleDone: (sink) {
          if (--_connectedClients == 0) {
            _lastClientDisconnected.complete();
          }

          sink.close();
        },
      )),
    );
  }
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

/// Utilities to complete an IndexedDB request.
extension CompleteIdbRequest on IDBRequest {
  /// Turns this request into a Dart future that completes with the first
  /// success or error event.
  Future<T> complete<T extends JSAny?>() {
    final completer = Completer<T>.sync();

    EventStreamProviders.successEvent.forTarget(this).listen((event) {
      completer.complete(result as T);
    });
    EventStreamProviders.errorEvent.forTarget(this).listen((event) {
      completer.completeError(error ?? event);
    });
    EventStreamProviders.blockedEvent.forTarget(this).listen((event) {
      completer.completeError(error ?? event);
    });

    return completer.future;
  }
}
