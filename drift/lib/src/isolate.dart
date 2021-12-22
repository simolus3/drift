import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:stream_channel/isolate_channel.dart';

import '../drift.dart';
import '../remote.dart';

// All of this is drift-internal and not exported, so:
// ignore_for_file: public_member_api_docs

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
        final channel = IsolateChannel(receiveForConnection, sendPort);

        server.serve(channel, serialize: serialize);
      }
    });

    server.done.then((_) {
      subscription.cancel();
      connectPort.close();
      if (killIsolateWhenDone) self.kill();
    });
  }
}
