/// Contains utils to run drift databases in a background isolate.
///
/// Please note that this API is not supported on the web.
library isolate;

import 'dart:isolate';

import 'package:stream_channel/stream_channel.dart';

import 'drift.dart';
import 'remote.dart';
import 'src/isolate.dart';

/// Signature of a function that opens a database connection.
typedef DatabaseOpener = DatabaseConnection Function();

/// Defines utilities to run drift in a background isolate. In the operation
/// mode created by these utilities, there's a single background isolate doing
/// all the work. Any other isolate can use the [connect] method to obtain an
/// instance of a [GeneratedDatabase] class that will delegate its work onto a
/// background isolate. Auto-updating queries, and transactions work across
/// isolates, and the user facing api is exactly the same.
///
/// Please note that, while running drift in a background isolate can reduce
/// latency in foreground isolates (thus reducing UI lags), the overall
/// performance is going to be much worse as data has to be serialized and
/// deserialized to be sent over isolates.
/// Also, be aware that this api is not available on the web.
///
/// See also:
/// - [Isolate], for general information on multi threading in Dart.
/// - The [detailed documentation](https://drift.simonbinder.eu/docs/advanced-features/isolates),
///   which provides example codes on how to use this api.
class DriftIsolate {
  /// The underlying port used to establish a connection with this
  /// [DriftIsolate].
  ///
  /// This [SendPort] can safely be sent over isolates. The receiving isolate
  /// can reconstruct a [DriftIsolate] by using [DriftIsolate.fromConnectPort].
  final SendPort connectPort;

  /// The flag indicating whether messages between this [DriftIsolate]
  /// and the [DriftServer] should be serialized.
  final bool serialize;

  /// Creates a [DriftIsolate] talking to another isolate by using the
  /// [connectPort].
  ///
  /// {@template drift_isolate_serialize}
  /// Internally, drift uses ports from `dart:isolate` to send commands to an
  /// internal server dispatching database actions.
  /// In most setups, those ports can send and receive almost any Dart object.
  /// In special cases though, the platform only supports sending simple types
  /// across send types. In particular, isolates across different Flutter
  /// engines (such as the ones spawned by the `workmanager` package) are
  /// unable to handle most objects.
  /// To support those setups, drift can serialize its internal communication
  /// channel to only send simple types across isolates. The [serialize]
  /// parameter, which is enabled by default, controls this behavior.
  ///
  /// In most scenarios, [serialize] can be disabled for a considerable
  /// performance improvement.
  /// {@endtemplate}
  DriftIsolate.fromConnectPort(this.connectPort, {this.serialize = true});

  StreamChannel _open() {
    final receive = ReceivePort('drift client receive');
    connectPort.send([receive.sendPort, serialize]);

    final controller =
        StreamChannelController(allowForeignErrors: false, sync: true);
    receive.listen((message) {
      if (message is SendPort) {
        controller.local.stream.listen(message.send, onDone: receive.close);
      } else {
        controller.local.sink.add(message);
      }
    });

    return controller.foreign;
  }

  /// Connects to this [DriftIsolate] from another isolate.
  ///
  /// All operations on the returned [DatabaseConnection] will be executed on a
  /// background isolate. Setting the [isolateDebugLog] is only helpful when
  /// debugging drift itself.
  // todo: breaking: Make synchronous in drift 2
  Future<DatabaseConnection> connect({bool isolateDebugLog = false}) async {
    return remote(_open(), debugLog: isolateDebugLog, serialize: serialize);
  }

  /// Stops the background isolate and disconnects all [DatabaseConnection]s
  /// created.
  /// If you only want to disconnect a database connection created via
  /// [connect], use [GeneratedDatabase.close] instead.
  Future<void> shutdownAll() {
    return shutdown(_open(), serialize: serialize);
  }

  /// Creates a new [DriftIsolate] on a background thread.
  ///
  /// The [opener] function will be used to open the [DatabaseConnection] used
  /// by the isolate. Most implementations are likely to use
  /// [DatabaseConnection.fromExecutor] instead of providing stream queries and
  /// the type system manually.
  ///
  /// Because [opener] will be called on another isolate with its own memory,
  /// it must either be a top-level member or a static class method.
  ///
  /// To close the isolate later, use [shutdownAll].
  ///
  /// {@macro drift_isolate_serialize}
  static Future<DriftIsolate> spawn(DatabaseOpener opener,
      {bool serialize = false}) async {
    final receiveServer = ReceivePort();
    final keyFuture = receiveServer.first;

    await Isolate.spawn(_startDriftIsolate, [receiveServer.sendPort, opener]);
    final key = await keyFuture as SendPort;
    return DriftIsolate.fromConnectPort(key, serialize: serialize);
  }

  /// Creates a [DriftIsolate] in the [Isolate.current] isolate. The returned
  /// [DriftIsolate] is an object than can be sent across isolates - any other
  /// isolate can then use [DriftIsolate.connect] to obtain a special database
  /// connection which operations are all executed on this isolate.
  ///
  /// When [killIsolateWhenDone] is enabled (it defaults to `false`) and
  /// [shutdownAll] is called on the returned [DriftIsolate], the isolate used
  /// to call [DriftIsolate.inCurrent] will be killed.
  ///
  /// {@macro drift_isolate_serialize}
  factory DriftIsolate.inCurrent(DatabaseOpener opener,
      {bool killIsolateWhenDone = false, bool serialize = false}) {
    final server = RunningDriftServer(Isolate.current, opener(),
        killIsolateWhenDone: killIsolateWhenDone);
    return DriftIsolate.fromConnectPort(
      server.portToOpenConnection,
      serialize: serialize,
    );
  }
}

/// Creates a [RunningDriftServer] and sends a [SendPort] that can be used to
/// establish connections.
///
/// Te [args] list must contain two elements. The first one is the [SendPort]
/// that [_startDriftIsolate] will use to send the new [SendPort] used to
/// establish further connections. The second element is a [DatabaseOpener]
/// used to open the underlying database connection.
void _startDriftIsolate(List args) {
  final sendPort = args[0] as SendPort;
  final opener = args[1] as DatabaseOpener;

  final server = RunningDriftServer(Isolate.current, opener());
  sendPort.send(server.portToOpenConnection);
}
