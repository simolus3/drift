//@dart=2.6

import 'dart:convert';
import 'dart:isolate';

import 'package:drift_dev/integrations/plugin.dart' as plugin;
import 'package:web_socket_channel/io.dart';

const useDebuggingVariant = false;

void main(List<String> args, SendPort sendPort) {
  if (useDebuggingVariant) {
    _PluginProxy(sendPort).start();
  } else {
    plugin.start(args, sendPort);
  }
}

// Used during development. See CONTRIBUTING.md in the drift repo on how to
// debug the plugin.
class _PluginProxy {
  final SendPort sendToAnalysisServer;

  ReceivePort _receive;
  IOWebSocketChannel _channel;

  _PluginProxy(this.sendToAnalysisServer);

  Future<void> start() async {
    _channel = IOWebSocketChannel.connect('ws://localhost:9999');
    _receive = ReceivePort();
    sendToAnalysisServer.send(_receive.sendPort);

    _receive.listen((data) {
      // the server will send messages as maps, convert to json
      _channel.sink.add(json.encode(data));
    });

    _channel.stream.listen((data) {
      sendToAnalysisServer.send(json.decode(data as String));
    });
  }
}
