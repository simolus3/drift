// ignore_for_file: public_member_api_docs
import 'dart:async';
import 'dart:html';

import 'package:js/js_util.dart';

import '../wasm_setup.dart';
import 'protocol.dart';
import 'shared.dart';
import 'types.dart';

class SharedDriftWorker {
  final SharedWorkerGlobalScope self;

  /// If we end up using [WasmStorageImplementation.opfsShared], this is the
  /// "shared-dedicated" worker hosting the database.
  Worker? _dedicatedWorker;

  final DriftServerController _servers;

  SharedDriftWorker(this.self, WasmDatabaseSetup? setup)
      : _servers = DriftServerController(setup);

  void start() {
    const event = EventStreamProvider<MessageEvent>('connect');
    event.forTarget(self).listen(_newConnection);
  }

  void _newConnection(MessageEvent event) async {
    final clientPort = event.ports[0];
    clientPort.onMessage
        .listen((event) => _messageFromClient(clientPort, event));
  }

  void _messageFromClient(MessagePort client, MessageEvent event) async {
    try {
      final message = WasmInitializationMessage.read(event);

      switch (message) {
        case RequestCompatibilityCheck(databaseName: var dbName):
          final result = await _startFeatureDetection(dbName);
          result.sendToPort(client);
        case ServeDriftDatabase(
            storage: WasmStorageImplementation.sharedIndexedDb
          ):
          // The shared indexed db implementation can be hosted directly in this
          // worker.
          _servers.serve(message);
        case ServeDriftDatabase():
          // Forward the request to the worker - this will also transfer the
          // port which means that the shared worker is not involved in the
          // remaining conversation.
          message.sendToWorker(_dedicatedWorker!);
        default:
          throw ArgumentError('Unknown message');
      }
    } catch (e) {
      WorkerError(e.toString()).sendToPort(client);
      client.close();
    }
  }

  Future<SharedWorkerCompatibilityResult> _startFeatureDetection(
      String databaseName) async {
    // First, let's see if this shared worker can spawn dedicated workers.
    final hasWorker = supportsWorkers;
    final canUseIndexedDb = await checkIndexedDbSupport();

    if (!hasWorker) {
      final indexedDbExists =
          _servers.servers[databaseName]?.storage.isIndexedDbBased ??
              await checkIndexedDbExists(databaseName);

      return SharedWorkerCompatibilityResult(
        canSpawnDedicatedWorkers: false,
        dedicatedWorkersCanUseOpfs: false,
        canUseIndexedDb: canUseIndexedDb,
        indexedDbExists: indexedDbExists,
        opfsExists: false,
        existingDatabases: const [],
      );
    } else {
      final worker = _dedicatedWorker ??= Worker(Uri.base.toString());

      // Ask the worker about the storage implementations it can support.
      RequestCompatibilityCheck(databaseName).sendToWorker(worker);

      final completer = Completer<SharedWorkerCompatibilityResult>();
      StreamSubscription? messageSubscription, errorSubscription;

      void result(
        bool opfsAvailable,
        bool opfsExists,
        bool indexedDbExists,
        List<ExistingDatabase> databases,
      ) {
        if (!completer.isCompleted) {
          completer.complete(SharedWorkerCompatibilityResult(
            canSpawnDedicatedWorkers: true,
            dedicatedWorkersCanUseOpfs: opfsAvailable,
            canUseIndexedDb: canUseIndexedDb,
            indexedDbExists: indexedDbExists,
            opfsExists: opfsExists,
            existingDatabases: databases,
          ));

          messageSubscription?.cancel();
          errorSubscription?.cancel();
        }
      }

      messageSubscription = worker.onMessage.listen((event) {
        final data =
            WasmInitializationMessage.fromJs(getProperty(event, 'data'));
        final compatibilityResult = data as DedicatedWorkerCompatibilityResult;

        result(
          compatibilityResult.canAccessOpfs,
          compatibilityResult.opfsExists,
          compatibilityResult.indexedDbExists,
          compatibilityResult.existingDatabases,
        );
      });

      errorSubscription = worker.onError.listen((event) {
        result(false, false, false, const []);
        worker.terminate();
        _dedicatedWorker = null;
      });

      return completer.future;
    }
  }
}
