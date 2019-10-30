import 'dart:async';
import 'dart:isolate';

import 'package:moor/moor.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';
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
/// - TODO: Write documentation tutorial for this on the website
///   also todo: Is MoorIsolate really a name we want to keep? It's not really
///   an isolate
class MoorIsolate {
  /// Identifier for the server isolate that we can connect to.
  final ServerKey _server;

  final Isolate _isolate;

  MoorIsolate._(this._server, this._isolate);

  /// Connects to this [MoorIsolate] from another isolate. All operations on the
  /// returned [DatabaseConnection] will be executed on a background isolate.
  /// Setting the [isolateDebugLog] is only helpful when debugging moor itself.
  Future<DatabaseConnection> connect({bool isolateDebugLog = false}) async {
    final client = await _MoorClient.connect(this, isolateDebugLog);
    return client._connection;
  }

  /// Calls [Isolate.kill] on the underlying isolate.
  void kill() {
    _isolate.kill();
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
    // todo: API to terminate the spawned isolate?
    final receiveServer = ReceivePort();
    final keyFuture = receiveServer.first;

    final isolate = await Isolate.spawn(
        _startMoorIsolate, [receiveServer.sendPort, opener]);
    final key = await keyFuture as ServerKey;
    return MoorIsolate._(key, isolate);
  }

  /// Creates a [MoorIsolate] in the [Isolate.current] isolate. The returned
  /// [MoorIsolate] is an object than can be sent across isolates - any other
  /// isolate can then use [MoorIsolate.connect] to obtain a special database
  /// connection which operations are all executed on this isolate.
  static MoorIsolate inCurrent(DatabaseOpener opener) {
    final server = _MoorServer(opener);
    return MoorIsolate._(server.key, Isolate.current);
  }
}

/// Creates a [_MoorServer] and sends the resulting [ServerKey] over a
/// [SendPort]. The [args] param must have two parameters, the first one being
/// a [SendPort] and the second one being a [DatabaseOpener].
void _startMoorIsolate(List args) {
  final sendPort = args[0] as SendPort;
  final opener = args[1] as DatabaseOpener;

  final server = _MoorServer(opener);
  sendPort.send(server.key);
}
