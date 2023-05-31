import 'dart:html';

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

  final opfsRoot = await storage.directory;
  const testFileName = '_drift_feature_detection';

  FileSystemFileHandle? fileHandle;
  FileSystemSyncAccessHandle? openedFile;

  try {
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

    if (fileHandle != null) {
      await opfsRoot.removeEntry(testFileName);
    }
  }
}

Future<bool> checkIndexedDbSupport() async {
  return true;
}

class DriftServerController {
  /// Running drift servers by the name of the database they're serving.
  final Map<String, DriftServer> _servers = {};

  void serve(ServeDriftDatabase message) {
    final server = _servers.putIfAbsent(message.databaseName, () {
      return DriftServer(LazyDatabase(() async {
        final sqlite3 = await WasmSqlite3.loadFromUrl(message.sqlite3WasmUri);

        final vfs = await switch (message.storage) {
          WasmStorageImplementation.opfsShared =>
            SimpleOpfsFileSystem.loadFromStorage(
                '/drift_db/${message.databaseName}'),
          WasmStorageImplementation.opfsLocks => _loadLockedWasmVfs(),
          WasmStorageImplementation.unsafeIndexedDb ||
          WasmStorageImplementation.sharedIndexedDb =>
            IndexedDbFileSystem.open(dbName: message.databaseName),
          WasmStorageImplementation.inMemory =>
            Future.value(InMemoryFileSystem()),
        };

        sqlite3.registerVirtualFileSystem(vfs, makeDefault: true);

        return WasmDatabase(sqlite3: sqlite3, path: '/database');
      }));
    });

    server.serve(message.port.channel());
  }

  Future<WasmVfs> _loadLockedWasmVfs() async {
    // Create SharedArrayBuffers to synchronize requests
    final options = WasmVfs.createOptions();
    final worker = Worker(Uri.base.toString());

    StartFileSystemServer(options).sendToWorker(worker);

    // Wait for the server worker to report that it's ready
    await worker.onMessage.first;

    return WasmVfs(workerOptions: options);
  }
}
