/// Utility functions enabling the use of web workers to accelerate drift on the
/// web.
///
/// For more details on how to use this library, see [the documentation].
///
/// [the documentation]: https://drift.simonbinder.eu/web/#using-web-workers
// ignore_for_file: public_member_api_docs

library drift.web.workers;

import 'dart:async';
import 'dart:html';
// import 'dart:html';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/src/web/channel.dart';
import 'package:stream_channel/stream_channel.dart';

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
  /// Note that only Firefox seems to support spawning dedicated workers in
  /// shared workers, which makes this option effectively unsupported on Chrome
  /// and Safari.
  dedicatedInShared;
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
  _RunningDriftWorker(true, openConnection).start();
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
    final chrome =
        (WorkerGlobalScope.instance as JSObject).getProperty("chrome".toJS);
    final runtime = (chrome as JSObject).getProperty("runtime".toJS);
    final jsPort = (runtime as JSObject)
        .callMethod("connect".toJS, ChromeConnectInfo(name: "drift database"));
    final port = jsPort as ChromeRuntimePort;
    // final worker = SharedWorker(workerJsUri, 'drift database');
    // final port = worker.port!;

    var didGetInitializationResponse = true;
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

  return connectToRemoteAndInitialize(channel);
}

extension type ChromeConnectInfo._(JSObject _) implements JSObject {
  external String get name;

  external ChromeConnectInfo({required String name});
}

@JS()
@staticInterop
class ChromeRuntimePort {}

extension ChromeRuntimePortX on ChromeRuntimePort {
  external void disconnect();
  @JS('postMessage')
  external void _postMessage(JSAny? message);

  void postMessage(Object? message) => _postMessage(message.jsify());

  external void close();

  external String get name;

  external ChromePortOnMessage get onMessage;
}

@JS()
@staticInterop
class ChromePortOnMessage {}

@JS()
@staticInterop
class ChromePortOnDisconnect {}

extension ChromeRuntimePortOnMessageX on ChromePortOnMessage {
  @JS('addListener')
  external void _addListener(JSExportedDartFunction listener);
  // external void _removeListener(JSExportedDartFunction listener);

  void addListener(ChromePortOnMessageListener listener) =>
      _addListener(listener.toJS);
}

typedef ChromePortOnMessageListener = void Function(
    JSAny? message, ChromeRuntimePort port);

const _disconnectMessage = '_disconnect';

/// Extension to transform a raw [MessagePort] from web workers into a Dart
/// [StreamChannel].
extension PortToChannel on ChromeRuntimePort {
  /// Converts this port to a two-way communication channel, exposed as a
  /// [StreamChannel].
  ///
  /// This can be used to implement a remote database connection over service
  /// workers.
  ///
  /// The [explicitClose] parameter can be used to control whether a close
  /// message should be sent through the channel when it is closed. This will
  /// cause it to be closed on the other end as well. Note that this is not a
  /// reliable way of determining channel closures though, as there is no event
  /// for channels being closed due to a tab or worker being closed.
  /// Both "ends" of a JS channel calling [channel] on their part must use the
  /// value for [explicitClose].
  StreamChannel<Object?> channel({bool explicitClose = false}) {
    final controller = StreamChannelController<Object?>();
    onMessage.addListener((message, port) {
      if (explicitClose && message == _disconnectMessage) {
        // Other end has closed the connection
        controller.local.sink.close();
      } else {
        controller.local.sink.add(message.dartify());
      }
    });

    controller.local.stream.listen(postMessage, onDone: () {
      // Closed locally, inform the other end.
      if (explicitClose) {
        postMessage(_disconnectMessage);
      }

      close();
    });

    return controller.foreign;
  }
}

class _RunningDriftWorker {
  final bool isShared;
  final QueryExecutor Function() connectionFactory;

  DriftServer? _startedServer;
  DriftWorkerMode? _knownMode;
  Worker? _dedicatedWorker;

  _RunningDriftWorker(this.isShared, this.connectionFactory);

  void start() {
    print("DOING DRIFT START");
    if (isShared) {
      final chrome = (self as JSObject).getProperty("chrome".toJS);
      final runtime = (chrome as JSObject).getProperty("runtime".toJS);
      final onConnect = (runtime as JSObject).getProperty("onConnect".toJS);
      (onConnect as JSObject).callMethod(
        "addListener".toJS,
        ((ChromeRuntimePort port) {
          print("CONNECTED");
          _newConnection(port);
        }).toJS,
      );
      // const event = EventStreamProvider<MessageEvent>('connect');
      // event.forTarget(self).listen(_newConnection);
    } else {
      print("DRIFT START NOT SHARED");
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
  void _newConnection(ChromeRuntimePort outgoingPort) {
    assert(isShared);

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
    } else {
      throw StateError('Received unknown message $message, expected a port');
    }
  }

  static WorkerGlobalScope get self => WorkerGlobalScope.instance;
}
