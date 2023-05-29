// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:html';

import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/wasm.dart';
import 'package:js/js_util.dart';
import 'package:sqlite3/wasm.dart';

import '../channel.dart';
import 'protocol.dart';
import 'shared.dart';

class DedicatedDriftWorker {
  final DedicatedWorkerGlobalScope self;

  /// Running drift servers by the name of the database they're serving.
  final Map<String, DriftServer> _servers = {};

  DedicatedDriftWorker(this.self);

  void start() {
    self.onMessage.listen((event) {
      final message = WasmInitializationMessage.read(event);
      _handleMessage(message);
    });
  }

  Future<void> _handleMessage(WasmInitializationMessage message) async {
    switch (message) {
      case DedicatedWorkerCompatibilityCheck():
        final supportsOpfs = await checkOpfsSupport();
        final supportsIndexedDb = await checkIndexedDbSupport();

        DedicatedWorkerCompatibilityResult(
          canAccessOpfs: supportsOpfs,
          supportsIndexedDb: supportsIndexedDb,
          supportsSharedArrayBuffers:
              hasProperty(globalThis, 'SharedArrayBuffer'),
        ).sendToClient(self);
      case ServeDriftDatabase():
        final server = _servers.putIfAbsent(message.databaseName, () {
          return DriftServer(LazyDatabase(() async {
            final sqlite3 =
                await WasmSqlite3.loadFromUrl(message.sqlite3WasmUri);

            final vfs = await switch (message.storage) {
              WasmStorageImplementation.opfsShared =>
                SimpleOpfsFileSystem.loadFromStorage(
                    '/drift_db/${message.databaseName}'),
              WasmStorageImplementation.opfsLocks => _loadLockedWasmVfs(),
              WasmStorageImplementation.unsafeIndexedDb =>
                IndexedDbFileSystem.open(dbName: message.databaseName),
              WasmStorageImplementation.inMemory =>
                Future.value(InMemoryFileSystem()),
            };

            sqlite3.registerVirtualFileSystem(vfs, makeDefault: true);

            return WasmDatabase(sqlite3: sqlite3, path: '/database');
          }));
        });

        server.serve(message.port.channel());
        break;
      default:
        break;
    }
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
