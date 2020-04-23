import 'dart:async';
import 'dart:isolate';

import 'package:moor/moor.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';
import 'package:pedantic/pedantic.dart';
import 'communication.dart';

part 'client.dart';
part 'protocol.dart';
part 'server.dart';

/// Signature of a function that opens a database connection.
typedef DatabaseOpener = DatabaseConnection Function();

/// Defines utilities to run moor in a background isolate. In the operation mode
/// created by these utilities, there's a single background isolate doing all
/// the work. Any other isolate can use the [connect] method to obtain an
/// instance of a [GeneratedDatabase] class that will delegate its work onto a
/// background isolate. Auto-updating queries, and transactions work across
/// isolates, and the user facing api is exactly the same.
///
/// Please note that, while running moor in a background isolate can reduce
/// latency in foreground isolates (thus reducing UI lags), the overall
/// performance is going to be much worse as data has to be serialized and
/// deserialized to be sent over isolates.
/// Also, be aware that this api is not available on the web.
///
/// See also:
/// - [Isolate], for general information on multi threading in Dart.
/// - The [detailed documentation](https://moor.simonbinder.eu/docs/advanced-features/isolates),
///   which provides example codes on how to use this api.
class MoorIsolate {
  /// THe underlying port used to establish a connection with this
  /// [MoorIsolate].
  ///
  /// This [SendPort] can safely be sent over isolates. The receiving isolate
  /// can reconstruct a[MoorIsolate] by using [MoorIsolate.fromConnectPort].
  final SendPort connectPort;

  /// Creates a [MoorIsolate] talking to another isolate by using the
  /// [connectPort].
  MoorIsolate.fromConnectPort(this.connectPort);

  /// Connects to this [MoorIsolate] from another isolate. All operations on the
  /// returned [DatabaseConnection] will be executed on a background isolate.
  /// Setting the [isolateDebugLog] is only helpful when debugging moor itself.
  Future<DatabaseConnection> connect({bool isolateDebugLog = false}) async {
    final client = await _MoorClient.connect(this, isolateDebugLog);
    return client._connection;
  }

  /// Stops the background isolate and disconnects all [DatabaseConnection]s
  /// created.
  /// If you only want to disconnect a database connection created via
  /// [connect], use [GeneratedDatabase.close] instead.
  Future<void> shutdownAll() async {
    final connection = await IsolateCommunication.connectAsClient(connectPort);
    unawaited(connection.request(_NoArgsRequest.terminateAll).then((_) {},
        onError: (_) {
      // the background isolate is closed before it gets a chance to reply
      // to the terminateAll request. Ignore the error
    }));

    await connection.closed;
  }

  /// Creates a new [MoorIsolate] on a background thread.
  ///
  /// The [opener] function will be used to open the [DatabaseConnection] used
  /// by the isolate. Most implementations are likely to use
  /// [DatabaseConnection.fromExecutor] instead of providing stream queries and
  /// the type system manually.
  ///
  /// Because [opener] will be called on another isolate with its own memory,
  /// it must either be a top-level member or a static class method.
  static Future<MoorIsolate> spawn(DatabaseOpener opener) async {
    final receiveServer = ReceivePort();
    final keyFuture = receiveServer.first;

    await Isolate.spawn(_startMoorIsolate, [receiveServer.sendPort, opener]);
    final key = await keyFuture as SendPort;
    return MoorIsolate.fromConnectPort(key);
  }

  /// Creates a [MoorIsolate] in the [Isolate.current] isolate. The returned
  /// [MoorIsolate] is an object than can be sent across isolates - any other
  /// isolate can then use [MoorIsolate.connect] to obtain a special database
  /// connection which operations are all executed on this isolate.
  factory MoorIsolate.inCurrent(DatabaseOpener opener) {
    final server = _MoorServer(opener);
    return MoorIsolate.fromConnectPort(server.portToOpenConnection);
  }
}

/// Creates a [_MoorServer] and sends a [SendPort] that can be used to establish
/// connections.
///
/// Te [args] list must contain two elements. The first one is the [SendPort]
/// that [_startMoorIsolate] will use to send the new [SendPort] used to
/// establish further connections. The second element is a [DatabaseOpener]
/// used to open the underlying database connection.
void _startMoorIsolate(List args) {
  final sendPort = args[0] as SendPort;
  final opener = args[1] as DatabaseOpener;

  final server = _MoorServer(opener);
  sendPort.send(server.portToOpenConnection);
}
