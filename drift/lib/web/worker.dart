/// Utility functions enabling the use of web workers to accelerate drift on the
/// web.
///
/// For more details on how to use this library, see [the documentation].
///
/// [the documentation]: https://drift.simonbinder.eu/web/#using-web-workers
library drift.web.workers;

import 'dart:async';
import 'dart:html';

import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/src/web/channel.dart';
import 'package:js/js_util.dart';
import 'package:stream_channel/stream_channel.dart';
// ignore: implementation_imports
import 'package:sqlite3/src/wasm/js_interop/file_system_access.dart' as fsa;

/// Describes the topology between clients (e.g. tabs) and the drift web worker
/// when spawned with [connectToDriftWorker].
///
/// For more details on the individial modes, see the documentation on
/// [dedicated], [shared] and [dedicatedInShared].
enum DriftWorkerMode {
  /// Starts a new, regular web [Worker] when [connectToDriftWorker] is called.
  ///
  /// This worker, which we expect is a Dart program calling [driftWorkerMain]
  /// in its `main` function compiled to JavaScript, will open a database
  /// connection internally.
  /// The connection returned by [connectToDriftWorker] will use a message
  /// channel between the initiating tab and this worker to run its operations
  /// on the worker, which can take load of the UI tab.

  /// However, it is not possible for a worker to be used across different tabs.
  /// To do that, [shared] or [dedicatedInShared] needs to be used.
  dedicated,

  /// Starts a [SharedWorker] that is used across several browsing contexts
  /// (e.g. tabs or even a custom worker you wrote).
  ///
  /// This shared worker, which we expect is a Dart program calling
  /// [driftWorkerMain] in its `main` function compiled to JavaScript, will open
  /// a database connection internally.
  /// Just like for [dedicated] connections, the connection returned by
  /// [connectToDriftWorker] will use a message channel between the current
  /// context and the (potentially existing) shared worker.
  ///
  /// So, while every tab uses its own connection, they all connect to the same
  /// shared worker. Thus, every tab has a view of the same logical database.
  /// Even stream queries are synchronized across all tabs.
  ///
  /// Note that shared worker may not be supported in all browsers.
  shared,

  /// This mode generally works very similar to [shared] in the sense that a
  /// shared worker is used and that all tabs calling [driftWorkerMain] get
  /// a view of the same database with synchronized stream queries.
  ///
  /// However, a technical difference is that the actual database is not opened
  /// in the shared worker itself. Instead, the shared worker creates a new
  /// [Worker] internally that will host the database and forwards incoming
  /// connections to this worker.
  /// Generally, it is recommended to use a [shared] worker. However, some
  /// database connections, such as the one based on the Origin-private File
  /// System web API, is only available in dedicated workers. This setup enables
  /// the use of such APIs.
  ///
  /// Note that shared worker may not be supported in all browsers.
  dedicatedInShared;
}

/// Results of calling [checkForCompatibility] - reports whether features used
/// to efficiently run drift on the web are supported in the current browser.
class DriftWebCompatibility {
  /// Whether the parts of the File System Access API providing the Origin-
  /// Private File System implementation are supported on this browser.
  final bool? opfsSupported;

  /// Whether dedicated workers ([Worker]) are supported in this browser.
  final bool dedicatedWorkersSupported;

  /// Whether shared workers ([SharedWorker]) are supported in this browser.
  final bool sharedWorkersSupported;

  DriftWebCompatibility._(this.opfsSupported, this.dedicatedWorkersSupported,
      this.sharedWorkersSupported);
}

enum _WorkerCommand {
  checkOpfsSupport,
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
  _RunningDriftWorker worker;

  if (self is SharedWorkerGlobalScope) {
    worker = _RunningDriftWorker(true, openConnection);
  } else if (self is DedicatedWorkerGlobalScope) {
    worker = _RunningDriftWorker(false, openConnection);
  } else {
    throw StateError('This worker is neither a shared nor a dedicated worker');
  }

  worker.start();
}

/// Spawn or connect to a web worker written with [driftWorkerMain].
///
/// Depending on the [mode] option, this method creates either a regular [Worker]
/// or attaches itself to an [SharedWorker] in the current browsing context.
/// For more details on the different modes, see [DriftWorkerMode]. By default,
/// a dedicated worker will be used ([DriftWorkerMode.dedicated]).
///
/// The [workerJsUri] describes the path to the worker (e.g.
/// `/database_worker.dart.js` if the original Dart file defining the worker is
/// in `web/database_worker.dart`).
///
/// When using a shared worker, the database (including stream queries!) are
/// shared across multiple tabs in realtime.
Future<DatabaseConnection> connectToDriftWorker(String workerJsUri,
    {DriftWorkerMode mode = DriftWorkerMode.dedicated}) {
  StreamChannel<Object?> channel;

  if (mode == DriftWorkerMode.dedicated) {
    final worker = Worker(workerJsUri);
    final webChannel = MessageChannel();

    // Transfer first port to the channel, we'll use the second port on this side.
    worker.postMessage(webChannel.port1, [webChannel.port1]);
    channel = webChannel.port2.channel();
  } else {
    final worker = SharedWorker(workerJsUri, 'drift database');
    final port = worker.port!;

    var didGetInitializationResponse = false;
    port.postMessage(mode.name);
    channel = port.channel().transformStream(StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        if (didGetInitializationResponse) {
          sink.add(data);
        } else {
          didGetInitializationResponse = true;

          final response = data as bool;
          if (response) {
            // Initialization ok, all good!
          } else {
            sink
              ..addError(StateError(
                  'Shared worker disagrees with desired mode $mode, is there '
                  'another tab using `connectToDriftWorker()` in a different '
                  'mode?'))
              ..close();
          }
        }
      },
    ));
  }

  return connectToRemoteAndInitialize(channel, debugLog: true);
}

/// Starts a dedicated worker to probe whether shared and dedicated workers are
/// available and whether the File System Access API is correctly implemented in
/// the current browser.
///
/// The [workerJsUri] is the URL of the worker calling `driftWorkerMain` - the
/// same one you'd use for [connectToDriftWorker].
///
/// The returned [DriftWebCompatibility] contains the results of the feature
/// detection.
Future<DriftWebCompatibility> checkForDriftWebCompatibility(
    String workerJsUri) async {
  final workersSupported = hasProperty(globalThis, 'Worker');
  final sharedWorkersSupported = hasProperty(globalThis, 'SharedWorker');

  if (!workersSupported) {
    return DriftWebCompatibility._(
        null, workersSupported, sharedWorkersSupported);
  }

  final worker = Worker(workerJsUri);
  final channel = MessageChannel();

  worker.postMessage(
      [_WorkerCommand.checkOpfsSupport.name, channel.port1], [channel.port1]);

  final opfsSupported = await channel.port2.onMessage
      .map((e) => e.data as bool)
      .first
      .timeout(const Duration(milliseconds: 300), onTimeout: () => false);
  worker.terminate();

  return DriftWebCompatibility._(
      opfsSupported, workersSupported, sharedWorkersSupported);
}

class _RunningDriftWorker {
  final bool isShared;
  final QueryExecutor Function() connectionFactory;

  DriftServer? _startedServer;
  DriftWorkerMode? _knownMode;
  Worker? _dedicatedWorker;

  _RunningDriftWorker(this.isShared, this.connectionFactory);

  void start() {
    if (isShared) {
      const event = EventStreamProvider<MessageEvent>('connect');
      event.forTarget(self).listen(_newConnection);
    } else {
      const event = EventStreamProvider<MessageEvent>('message');
      event.forTarget(self).map((e) => e.data).listen(_handleMessage);
    }
  }

  DriftServer _establishModeAndLaunchServer(DriftWorkerMode mode) {
    _knownMode = mode;
    final server = _startedServer = DriftServer(
      connectionFactory(),
      allowRemoteShutdown: mode == DriftWorkerMode.dedicated,
    );

    server.done.whenComplete(() {
      // The only purpose of this worker is to start the drift server, so if the
      // server is done, so is the worker.
      if (isShared) {
        SharedWorkerGlobalScope.instance.close();
      } else {
        DedicatedWorkerGlobalScope.instance.close();
      }
    });

    return server;
  }

  /// Handle a new connection, which implies that this worker is shared.
  void _newConnection(MessageEvent event) {
    assert(isShared);
    final outgoingPort = event.ports.first;

    // We still don't know whether this shared worker is supposed to host the
    // server itself or whether this is delegated to a dedicated worker managed
    // by the shared worker. In our protocol, the client will tell us the
    // expected mode in its first message.
    final originalChannel = outgoingPort.channel();
    StreamSubscription<Object?>? subscription;

    StreamChannel<Object?> remainingChannel() {
      return originalChannel
          .changeStream((_) => SubscriptionStream(subscription!));
    }

    subscription = originalChannel.stream.listen((first) {
      final expectedMode = DriftWorkerMode.values.byName(first as String);

      if (_knownMode == null) {
        switch (expectedMode) {
          case DriftWorkerMode.dedicated:
            // This is a shared worker, so this mode won't work
            originalChannel.sink
              ..add(false)
              ..close();
            break;
          case DriftWorkerMode.shared:
            // Ok, we're supposed to run a drift server in this worker. Let's do
            // that then.
            final server =
                _establishModeAndLaunchServer(DriftWorkerMode.shared);
            originalChannel.sink.add(true);
            server.serve(remainingChannel());
            break;
          case DriftWorkerMode.dedicatedInShared:
            // Instead of running a server ourselves, we're starting a dedicated
            // child worker and forward the port.
            _knownMode = DriftWorkerMode.dedicatedInShared;
            final worker = _dedicatedWorker = Worker(Uri.base.toString());

            // This will call [_handleMessage], but in the context of the
            // dedicated worker we just created.
            outgoingPort.postMessage(true);
            worker.postMessage(outgoingPort, [outgoingPort]);

            // This closes the channel, but doesn't close the port since it has
            // been transferred to the child worker.
            originalChannel.sink.close();
            break;
        }
      } else if (_knownMode == expectedMode) {
        outgoingPort.postMessage(true);
        switch (_knownMode!) {
          case DriftWorkerMode.dedicated:
            // This is a shared worker, we won't ever set our mode to this.
            throw AssertionError();
          case DriftWorkerMode.shared:
            _startedServer!.serve(remainingChannel());
            break;
          case DriftWorkerMode.dedicatedInShared:
            _dedicatedWorker!.postMessage(outgoingPort, [outgoingPort]);
            originalChannel.sink.close();
            break;
        }
      } else {
        // Unsupported mode
        originalChannel.sink
          ..add(false)
          ..close();
      }
    });
  }

  /// Handle an incoming message for a dedicated worker.
  void _handleMessage(Object? message) async {
    assert(!isShared);
    assert(_knownMode != DriftWorkerMode.shared);

    if (message is MessagePort) {
      final server = _startedServer ??
          _establishModeAndLaunchServer(DriftWorkerMode.dedicated);
      server.serve(message.channel());
    } else if (message is List) {
      final command = message[0] as String;
      final responsePort = message[1] as MessagePort;

      try {
        final recognizedCommand = _WorkerCommand.values.byName(command);

        switch (recognizedCommand) {
          case _WorkerCommand.checkOpfsSupport:
            responsePort.postMessage(await _supportsOpfs());
            break;
        }
      } catch (_) {
        responsePort.postMessage(false);
      }
    } else {
      throw StateError('Received unknown message $message, expected a port');
    }
  }

  static WorkerGlobalScope get self => WorkerGlobalScope.instance;
}

Future<bool> _supportsOpfs() async {
  final manager = fsa.storageManager;
  if (manager == null) return false;

  const testName = '__drift_feature_check__';

  // Some implementations of this API follow an old standard that we don't
  // support. We can detect this by getSize() returning a promise.
  final root = await manager.directory;
  fsa.FileSystemFileHandle? file;
  fsa.FileSystemSyncAccessHandle? handle;

  try {
    file = await root.openFile(testName, create: true);
    handle = await file.createSyncAccessHandle();

    final getSizeCall = callMethod(handle, 'getSize', []);
    if (getSizeCall is! int) {
      // Asynchronous -> Not supported!
      return false;
    }

    return true;
  } finally {
    if (handle != null) {
      final closeCall = callMethod(handle, 'close', []);
      if (closeCall is Object) {
        await promiseToFuture(closeCall);
      }
    }

    if (file != null) {
      await root.removeEntry(testName);
    }
  }
}
