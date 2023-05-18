import 'dart:async';
import 'dart:html';

import 'package:drift/wasm.dart';
import 'package:drift/src/web/wasm_setup.dart';
import 'package:js/js_util.dart';

Future<void> main() async {
  final self = WorkerGlobalScope.instance;

  if (self is SharedWorkerGlobalScope) {
    // This is a shared worker. It responds
    _SharedDriftServer(self).start();
  } else {}
}

class _SharedDriftServer {
  final SharedWorkerGlobalScope self;

  /// If we end up using [WasmStorageImplementation.opfsShared], this is the
  /// "shared-dedicated" worker hosting the database.
  Worker? _dedicatedWorker;
  Future<SharedWorkerSupportedFlags>? _featureDetection;

  _SharedDriftServer(this.self);

  void start() {
    const event = EventStreamProvider<MessageEvent>('connect');
    event.forTarget(self).listen(_newConnection);
  }

  void _newConnection(MessageEvent event) async {
    // Start a feature detection run and inform the client about what we can do.
    final detectionFuture = (_featureDetection ??= _startFeatureDetection());
    final responsePort = event.ports[0];

    try {
      final result = await detectionFuture;
      responsePort.postMessage(WorkerInitializationMessage(
          type: SharedWorkerSupportedFlags.type, payload: result));
    } catch (e) {
      responsePort.postMessage(WorkerInitializationMessage(
          type: WorkerSetupError.type, payload: WorkerSetupError()));
    }
  }

  Future<SharedWorkerSupportedFlags> _startFeatureDetection() async {
    // First, let's see if this shared worker can spawn dedicated workers.
    final hasWorker = hasProperty(self, 'Worker');
    final canUseIndexedDb = await checkIndexedDbSupport();

    if (!hasWorker) {
      return SharedWorkerSupportedFlags(
        canSpawnDedicatedWorkers: false,
        dedicatedCanUseOpfs: false,
        canUseIndexedDb: canUseIndexedDb,
      );
    } else {
      final worker = _dedicatedWorker = Worker(Uri.base.toString());

      // Tell the worker that we want to use it to host a shared OPFS database.
      // It will respond with whether it can do that.
      worker.postMessage(WorkerInitializationMessage(
        type: DedicatedWorkerPurpose.type,
        payload: DedicatedWorkerPurpose(
          purpose: DedicatedWorkerPurpose.purposeSharedOpfs,
        ),
      ));

      final completer = Completer<SharedWorkerSupportedFlags>();
      StreamSubscription? messageSubscription, errorSubscription;

      void result(bool result) {
        if (!completer.isCompleted) {
          completer.complete(SharedWorkerSupportedFlags(
            canSpawnDedicatedWorkers: true,
            dedicatedCanUseOpfs: result,
            canUseIndexedDb: canUseIndexedDb,
          ));

          messageSubscription?.cancel();
          errorSubscription?.cancel();
        }
      }

      messageSubscription = worker.onMessage.listen((event) {
        result(event.data as bool);
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
