/// Utility functions enabling the use of web workers to accelerate drift on the
/// web.
///
/// For more details on how to use this library, see [the documentation].
///
/// [the documentation]: https://drift.simonbinder.eu/web/#using-web-workers
library drift.web.workers;

import 'dart:html';

import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/src/web/channel.dart';
import 'package:stream_channel/stream_channel.dart';

StreamChannel _postMessageChannel(
  EventTarget target,
  void Function(Object?) postMessage,
) {
  final channelController = StreamChannelController();
  final onMessage =
      const EventStreamProvider<MessageEvent>('message').forTarget(target);

  final messageSubscription =
      onMessage.map((e) => e.data).listen(channelController.local.sink.add);
  channelController.local.stream.listen(
    postMessage,
    onDone: messageSubscription.cancel,
  );

  return channelController.foreign;
}

/// A suitable entrypoint for a web worker aiming to make a drift database
/// available to other browsing contexts.
///
/// This function will detect whether it is running in a shared or in a
/// dedicated worker. In either case, the [openConnection] callback is invoked
/// to start a [DriftServer] that will serve drift database requests to clients.
///
/// When running in a shared worker, this function listens to
/// [SharedWorkerGlobalScope.onConnect] events and establishes message channels
/// with connecting clients to share a database.
/// In a dedicated worker, a [DedicatedWorkerGlobalScope.postMessage]-construction
/// is used to establish a communication channel with clients.
/// To connect to this worker, the [connectToDriftWorker] function can be used.
///
/// As an example, a worker file could live in `web/database_worker.dart` and
/// have the following content:
///
/// ```dart
/// import 'dart:html';
///
/// import 'package:drift/drift.dart';
/// import 'package:drift/web.dart';
/// import 'package:drift/web/worker.dart';
///
/// void main() {
///   // Load sql.js library in the worker
///   WorkerGlobalScope.instance.importScripts('sql-wasm.js');
///
///   driftWorkerMain(() {
///     return WebDatabase.withStorage(DriftWebStorage.indexedDb('worker',
///         migrateFromLocalStorage: false, inWebWorker: true));
///   });
/// }
/// ```
///
/// Depending on the build system you use, you can then compile this Dart web
/// worker with `dart compile js`, `build_web_compilers` or other tools.
///
/// The [connectToDriftWorker] method can be used in the main portion of your
/// app to connect to a worker using [driftWorkerMain].
///
/// The [documentation](https://drift.simonbinder.eu/web/#using-web-workers)
/// contains additional information and an example on how to use workers with
/// Dart and Drift.
void driftWorkerMain(QueryExecutor Function() openConnection) {
  final self = WorkerGlobalScope.instance;
  DriftServer server;
  void Function() close;

  if (self is SharedWorkerGlobalScope) {
    close = self.close;
    server = DriftServer(openConnection());

    // A shared worker can serve multiple tabs through channels
    self.onConnect.listen((event) {
      final msg = event as MessageEvent;
      server.serve(msg.ports.first.channel());
    });
  } else if (self is DedicatedWorkerGlobalScope) {
    close = self.close;
    server = DriftServer(openConnection(), allowRemoteShutdown: true);

    // A dedicated worker can only serve a single originating tab through a
    // channel created by `postMessage` calls.
    server.serve(_postMessageChannel(self, self.postMessage));
  } else {
    throw StateError('This worker is neither a shared nor a dedicated worker');
  }

  server.done.whenComplete(close);
}

/// Spawn or connect to a web worker written with [driftWorkerMain].
///
/// Depending on the [shared] flag, this method creates either a regular [Worker]
/// or a [SharedWorker] in the currenct context. The [workerJsUri] describes the
/// path to the worker (e.g. `/database_worker.dart.js` if the original Dart
/// file defining the worker is in `web/database_worker.dart`).
///
/// When using a shared worker, the database (including stream queries!) are
/// shared across multiple tabs in realtime.
Future<DatabaseConnection> connectToDriftWorker(String workerJsUri,
    {bool shared = false}) {
  const name = 'drift database';

  if (shared) {
    final worker = SharedWorker(workerJsUri, name);

    return connectToRemoteAndInitialize(worker.port!.channel());
  } else {
    final worker = Worker(workerJsUri);

    return connectToRemoteAndInitialize(
      _postMessageChannel(worker, worker.postMessage),
      singleClientMode: true,
    );
  }
}
