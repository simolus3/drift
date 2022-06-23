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

  _PluginProxy(this.sendToAnalysisServer);

  Future<void> start() async {
    final channel = IOWebSocketChannel.connect('ws://localhost:9999');
    final receive = ReceivePort();
    sendToAnalysisServer.send(receive.sendPort);

    receive.listen((data) {
      // the server will send messages as maps, convert to json
      channel.sink.add(json.encode(data));
    });

    channel.stream.listen((data) {
      sendToAnalysisServer.send(json.decode(data as String));
    });
  }
}
