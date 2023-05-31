// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:html';

import 'package:js/js_util.dart';
import 'package:sqlite3/wasm.dart';

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
      case DedicatedWorkerCompatibilityCheck():
        final supportsOpfs = await checkOpfsSupport();
        final supportsIndexedDb = await checkIndexedDbSupport();

        DedicatedWorkerCompatibilityResult(
          supportsNestedWorkers: hasProperty(globalThis, 'Worker'),
          canAccessOpfs: supportsOpfs,
          supportsIndexedDb: supportsIndexedDb,
          supportsSharedArrayBuffers:
              hasProperty(globalThis, 'SharedArrayBuffer'),
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
