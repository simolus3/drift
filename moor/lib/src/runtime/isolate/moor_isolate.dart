import 'dart:async';
import 'dart:isolate';

import 'package:moor/moor.dart';

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
class MoorIsolate {
  /// The [SendPort] created by the background isolate running the db. We'll use
  /// this port to initialize a connection to the background isolate. Further
  /// communication happens across a port that is specific for each client
  /// isolate.
  SendPort _connectToDb;

  static Future<MoorIsolate> spawn() {}

  static MoorIsolate inCurrent() {}

  Future<T> connect<T extends GeneratedDatabase>() {
    final client = _Client();
    return client._connectVia(this);
  }
}
