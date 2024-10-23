import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import '../drift.dart';
import '../remote.dart';

// All of this is drift-internal and not exported, so:
// ignore_for_file: public_member_api_docs

@internal
const disconnectMessage = '_disconnect';

final class _RegularInstance {}

@internal
Future<(StreamChannel, bool)> connectToServer(
  SendPort serverConnectPort,
  bool? serialize,
  Duration? connectionTimeout,
) async {
  if (serialize == null) {
    // Try to send a complex object over to see if we need to enable
    // serialization.
    try {
      serverConnectPort.send(_RegularInstance());
      serialize = false;
    } on ArgumentError {
      serialize = true;
    }
  }

  // The handshake starts with us sending a send port to the remote isolate.
  // If the isolate accepts the connection, it sends us a send port back which
  // is then used for the rest of the communication.
  final receive = ReceivePort('drift client receive');
  serverConnectPort.send([receive.sendPort, serialize]);

  final controller =
      StreamChannelController<Object?>(allowForeignErrors: false, sync: true);
  final completer = Completer<StreamChannel<Object?>>.sync();

  final timer = connectionTimeout != null
      ? Timer(connectionTimeout, () {
          receive.close();
          controller.local.sink.close();
          completer.completeError(TimeoutException(
              'No response from drift isolate received', connectionTimeout));
        })
      : null;

  receive.listen((message) {
    if (message is SendPort) {
      // Connection accepted! Cancel timeout and return connection
      timer?.cancel();

      controller.local.stream.listen(message.send, onDone: () {
        // Closed locally - notify the remote end about this.
        message.send(disconnectMessage);
        receive.close();
      });

      completer.complete(controller.foreign);
    } else if (message == disconnectMessage) {
      // Server has closed the connection
      controller.local.sink.close();
    } else {
      controller.local.sink.add(message);
    }
  });

  return (await completer.future, serialize);
}

@internal
class RunningDriftServer {
  final Isolate self;
  final bool killIsolateWhenDone;
  final bool onlyAcceptSingleConnection;
  final bool shutDownAfterLastDisconnect;

  final DriftServer server;
  final ReceivePort connectPort;
  final void Function()? beforeShutdown;
  int _counter = 0;
  int _activeConnections = 0;

  SendPort get portToOpenConnection => connectPort.sendPort;

  RunningDriftServer(
    this.self,
    QueryExecutor connection, {
    this.killIsolateWhenDone = true,
    bool closeConnectionAfterShutdown = true,
    this.onlyAcceptSingleConnection = false,
    this.beforeShutdown,
    this.shutDownAfterLastDisconnect = false,
    ReceivePort? port,
  })  : connectPort = port ?? ReceivePort('drift connect'),
        server = DriftServer(
          connection,
          allowRemoteShutdown: true,
          closeConnectionAfterShutdown: closeConnectionAfterShutdown,
        ) {
    final subscription = connectPort.listen((message) {
      if (message is List && message.length == 2) {
        if (onlyAcceptSingleConnection) {
          connectPort.close();
        }

        final sendPort = message[0]! as SendPort;
        final serialize = message[1]! as bool;
        final receiveForConnection =
            ReceivePort('drift channel #${_counter++}');
        sendPort.send(receiveForConnection.sendPort);

        final controller = StreamChannelController<Object?>(
            allowForeignErrors: false, sync: true);
        receiveForConnection.listen((message) {
          if (message == disconnectMessage) {
            // Client closed the connection
            controller.local.sink.close();

            if (onlyAcceptSingleConnection) {
              // The only connection was closed, so shut down the server.
              server.shutdown();
            }
          } else {
            controller.local.sink.add(message);
          }
        });
        controller.local.stream.listen(sendPort.send, onDone: () {
          // Closed locally - notify the client about this.
          receiveForConnection.close();
          sendPort.send(disconnectMessage);
        });

        _activeConnections++;
        server.serve(controller.foreign, serialize: serialize).whenComplete(() {
          _activeConnections--;

          if (_activeConnections == 0 && shutDownAfterLastDisconnect) {
            server.shutdown();
          }
        });
      }
    });

    server.done.then((_) {
      beforeShutdown?.call();
      subscription.cancel();
      connectPort.close();

      if (killIsolateWhenDone) self.kill();
    });
  }
}
