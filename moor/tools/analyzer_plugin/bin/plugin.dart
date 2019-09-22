import 'dart:convert';
import 'dart:isolate';

//import 'package:moor_generator/plugin.dart';
import 'package:web_socket_channel/io.dart';

const useProxyPlugin = true;

void main(List<String> args, SendPort sendPort) {
  PluginProxy(sendPort).start();
//  start(args, sendPort);
}

class PluginProxy {
  final SendPort sendToAnalysisServer;

  ReceivePort _receive;
  IOWebSocketChannel _channel;

  PluginProxy(this.sendToAnalysisServer);

  void start() async {
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
