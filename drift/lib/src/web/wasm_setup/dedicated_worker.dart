// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:html';

import 'package:drift/wasm.dart';
import 'package:js/js_util.dart';
import 'package:sqlite3/wasm.dart';

import '../../utils/synchronized.dart';
import 'protocol.dart';
import 'shared.dart';

class DedicatedDriftWorker {
  final DedicatedWorkerGlobalScope self;
  final Lock _checkCompatibility = Lock();

  final DriftServerController _servers = DriftServerController();
  WasmCompatibility? _compatibility;

  DedicatedDriftWorker(this.self);

  void start() {
    self.onMessage.listen((event) {
      final message = WasmInitializationMessage.read(event);
      _handleMessage(message);
    });
  }

  Future<void> _handleMessage(WasmInitializationMessage message) async {
    switch (message) {
      case RequestCompatibilityCheck(databaseName: var dbName):
        bool supportsOpfs = false, supportsIndexedDb = false;

        await _checkCompatibility.synchronized(() async {
          final knownResults = _compatibility;

          if (knownResults != null) {
            supportsOpfs = knownResults.supportsOpfs;
            supportsIndexedDb = knownResults.supportsIndexedDb;
          } else {
            supportsOpfs = await checkOpfsSupport();
            supportsIndexedDb = await checkIndexedDbSupport();
            _compatibility = WasmCompatibility(supportsIndexedDb, supportsOpfs);
          }
        });

        final existingServer = _servers.servers[dbName];

        var indexedDbExists = false, opfsExists = false;
        final existingDatabases = <(DatabaseLocation, String)>[];

        if (supportsOpfs) {
          for (final database in await opfsDatabases()) {
            existingDatabases.add((DatabaseLocation.opfs, database));

            if (database == dbName) {
              opfsExists = true;
            }
          }
        }

        if (existingServer != null) {
          indexedDbExists = existingServer.storage.isIndexedDbBased;
          opfsExists = existingServer.storage.isOpfsBased;
        } else if (supportsIndexedDb) {
          indexedDbExists = await checkIndexedDbExists(dbName);
        }

        DedicatedWorkerCompatibilityResult(
          supportsNestedWorkers: hasProperty(globalThis, 'Worker'),
          canAccessOpfs: supportsOpfs,
          supportsIndexedDb: supportsIndexedDb,
          supportsSharedArrayBuffers:
              hasProperty(globalThis, 'SharedArrayBuffer'),
          opfsExists: opfsExists,
          indexedDbExists: indexedDbExists,
          existingDatabases: existingDatabases,
        ).sendToClient(self);
      case ServeDriftDatabase():
        _servers.serve(message);
      case StartFileSystemServer(sqlite3Options: final options):
        final worker = await VfsWorker.create(options);
        self.postMessage(true);
        await worker.start();
      default:
        break;
    }
  }
}
