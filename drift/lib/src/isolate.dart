import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';

import '../drift.dart';
import '../remote.dart';

// All of this is drift-internal and not exported, so:
// ignore_for_file: public_member_api_docs

@internal
const disconnectMessage = '_disconnect';

@internal
StreamChannel connectToServer(SendPort serverConnectPort, bool serialize) {
  final receive = ReceivePort('drift client receive');
  serverConnectPort.send([receive.sendPort, serialize]);

  final controller =
      StreamChannelController(allowForeignErrors: false, sync: true);
  receive.listen((message) {
    if (message is SendPort) {
      controller.local.stream.listen(message.send, onDone: () {
        // Closed locally - notify the remote end about this.
        message.send(disconnectMessage);
        receive.close();
      });
    } else if (message == disconnectMessage) {
      // Server has closed the connection
      controller.local.sink.close();
    } else {
      controller.local.sink.add(message);
    }
  });

  return controller.foreign;
}

@internal
class RunningDriftServer {
  final Isolate self;
  final bool killIsolateWhenDone;

  final DriftServer server;
  final ReceivePort connectPort = ReceivePort('drift connect');
  int _counter = 0;

  SendPort get portToOpenConnection => connectPort.sendPort;

  RunningDriftServer(this.self, DatabaseConnection connection,
      {this.killIsolateWhenDone = true})
      : server = DriftServer(connection, allowRemoteShutdown: true) {
    final subscription = connectPort.listen((message) {
      if (message is List && message.length == 2) {
        final sendPort = message[0]! as SendPort;
        final serialize = message[1]! as bool;
        final receiveForConnection =
            ReceivePort('drift channel #${_counter++}');
        sendPort.send(receiveForConnection.sendPort);

        final controller =
            StreamChannelController(allowForeignErrors: false, sync: true);
        receiveForConnection.listen((message) {
          if (message == disconnectMessage) {
            // Client closed the connection
            controller.local.sink.close();
          } else {
            controller.local.sink.add(message);
          }
        });
        controller.local.stream.listen(sendPort.send, onDone: () {
          // Closed locally - notify the client about this.
          receiveForConnection.close();
          sendPort.send(disconnectMessage);
        });

        server.serve(controller.foreign, serialize: serialize);
      }
    });

    server.done.then((_) {
      subscription.cancel();
      connectPort.close();
      if (killIsolateWhenDone) self.kill();
    });
  }
}
