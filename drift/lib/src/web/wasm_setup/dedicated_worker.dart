// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';

import 'package:js/js_util.dart';
import 'package:sqlite3/wasm.dart';
// ignore: implementation_imports
import 'package:sqlite3/src/wasm/js_interop/file_system_access.dart';
import 'package:path/path.dart' as p;

import 'protocol.dart';
import 'shared.dart';

class DedicatedDriftWorker {
  final DedicatedWorkerGlobalScope self;
  final DriftServerController _servers = DriftServerController();

  DedicatedDriftWorker(this.self);

  void start() {
    self.onMessage.listen((event) {
      final message = WasmInitializationMessage.read(event);
      _handleMessage(message);
    });
  }

  Future<void> _handleMessage(WasmInitializationMessage message) async {
    switch (message) {
      case DedicatedWorkerCompatibilityCheck(databaseName: var dbName):
        final supportsOpfs = await checkOpfsSupport();
        final supportsIndexedDb = await checkIndexedDbSupport();

        var opfsExists = false;
        var indexedDbExists = false;

        if (dbName != null) {
          if (supportsOpfs) {
            final storage = storageManager!;
            final pathSegments = p.url.split(pathForOpfs(dbName));

            var directory = await storage.directory;
            opfsExists = true;

            for (final segment in pathSegments) {
              try {
                directory = await directory.getDirectory(segment);
              } on Object {
                opfsExists = false;
                break;
              }
            }
          } else if (supportsIndexedDb) {
            final indexedDb = getProperty<IdbFactory>(globalThis, 'indexedDB');

            await indexedDb.open(dbName, version: 1, onUpgradeNeeded: (event) {
              event.target.transaction!.abort();
              indexedDbExists =
                  event.oldVersion != null && event.oldVersion != 0;
            });
          }
        }

        DedicatedWorkerCompatibilityResult(
          supportsNestedWorkers: hasProperty(globalThis, 'Worker'),
          canAccessOpfs: supportsOpfs,
          supportsIndexedDb: supportsIndexedDb,
          supportsSharedArrayBuffers:
              hasProperty(globalThis, 'SharedArrayBuffer'),
          opfsExists: opfsExists,
          indexedDbExists: indexedDbExists,
        ).sendToClient(self);
      case ServeDriftDatabase():
        _servers.serve(message);
      case StartFileSystemServer(sqlite3Options: final options):
        final worker = await VfsWorker.create(options);
        await worker.start();
      default:
        break;
    }
  }
}
