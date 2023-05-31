// ignore_for_file: public_member_api_docs
import 'dart:async';
import 'dart:html';

import 'package:drift/wasm.dart';
import 'package:js/js_util.dart';

import 'protocol.dart';
import 'shared.dart';

class SharedDriftWorker {
  final SharedWorkerGlobalScope self;

  /// If we end up using [WasmStorageImplementation.opfsShared], this is the
  /// "shared-dedicated" worker hosting the database.
  Worker? _dedicatedWorker;
  Future<SharedWorkerStatus>? _featureDetection;

  final DriftServerController _servers = DriftServerController();

  SharedDriftWorker(this.self);

  void start() {
    const event = EventStreamProvider<MessageEvent>('connect');
    event.forTarget(self).listen(_newConnection);
  }

  void _newConnection(MessageEvent event) async {
    // Start a feature detection run and inform the client about what we can do.
    final detectionFuture = (_featureDetection ??= _startFeatureDetection());
    final clientPort = event.ports[0];

    try {
      final result = await detectionFuture;
      result.sendToPort(clientPort);
    } catch (e, s) {
      WorkerError(e.toString() + s.toString()).sendToPort(clientPort);
    }

    clientPort.onMessage
        .listen((event) => _messageFromClient(clientPort, event));
  }

  void _messageFromClient(MessagePort client, MessageEvent event) async {
    try {
      final message = WasmInitializationMessage.read(event);

      switch (message) {
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

  Future<SharedWorkerStatus> _startFeatureDetection() async {
    // First, let's see if this shared worker can spawn dedicated workers.
    final hasWorker = hasProperty(self, 'Worker');
    final canUseIndexedDb = await checkIndexedDbSupport();

    if (!hasWorker) {
      return SharedWorkerStatus(
        canSpawnDedicatedWorkers: false,
        dedicatedWorkersCanUseOpfs: false,
        canUseIndexedDb: canUseIndexedDb,
      );
    } else {
      final worker = _dedicatedWorker = Worker(Uri.base.toString());

      // Ask the worker about the storage implementations it can support.
      DedicatedWorkerCompatibilityCheck().sendToWorker(worker);

      final completer = Completer<SharedWorkerStatus>();
      StreamSubscription? messageSubscription, errorSubscription;

      void result(bool result) {
        if (!completer.isCompleted) {
          completer.complete(SharedWorkerStatus(
            canSpawnDedicatedWorkers: true,
            dedicatedWorkersCanUseOpfs: result,
            canUseIndexedDb: canUseIndexedDb,
          ));

          messageSubscription?.cancel();
          errorSubscription?.cancel();
        }
      }

      messageSubscription = worker.onMessage.listen((event) {
        final data =
            WasmInitializationMessage.fromJs(getProperty(event, 'data'));

        result((data as DedicatedWorkerCompatibilityResult).canAccessOpfs);
      });

      errorSubscription = worker.onError.listen((event) {
        result(false);
        worker.terminate();
        _dedicatedWorker = null;
      });

      return completer.future;
    }
  }
}
