import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/starter.dart';
import 'package:moor_generator/src/backends/plugin/plugin.dart';

void start(List<String> args, SendPort sendPort) {
  ServerPluginStarter(MoorPlugin(PhysicalResourceProvider.INSTANCE))
      .start(sendPort);
}

class WebSocketPluginServer implements PluginCommunicationChannel {
  final dynamic address;
  final int port;

  HttpServer server;

  WebSocket _currentClient;
  final StreamController<WebSocket> _clientStream =
      StreamController.broadcast();

  WebSocketPluginServer({dynamic address, this.port = 9999})
      : address = address ?? InternetAddress.loopbackIPv4 {
    _init();
  }

  void _init() async {
    server = await HttpServer.bind(address, port);
    print('listening on $address at port $port');
    server.transform(WebSocketTransformer()).listen(_handleClientAdded);
  }

  void _handleClientAdded(WebSocket socket) {
    if (_currentClient != null) {
      print(
          'ignoring connection attempt because an active client already exists');
      socket.close();
    } else {
      print('client connected');
      _currentClient = socket;
      _clientStream.add(_currentClient);
      _currentClient.done.then((_) {
        print('client disconnected');
        _currentClient = null;
        _clientStream.add(null);
      });
    }
  }

  @override
  void close() {
    server?.close(force: true);
  }

  @override
  void listen(void Function(Request request) onRequest,
      {Function onError, void Function() onDone}) {
    final stream = _clientStream.stream;

    // wait until we're connected
    stream.firstWhere((socket) => socket != null).then((_) {
      _currentClient.listen((data) {
        print('I: $data');
        onRequest(Request.fromJson(
            json.decode(data as String) as Map<String, dynamic>));
      });
    });
    stream.firstWhere((socket) => socket == null).then((_) => onDone());
  }

  @override
  void sendNotification(Notification notification) {
    print('N: ${notification.toJson()}');
    _currentClient?.add(json.encode(notification.toJson()));
  }

  @override
  void sendResponse(Response response) {
    print('O: ${response.toJson()}');
    _currentClient?.add(json.encode(response.toJson()));
  }
}

/// Starts the plugin over a websocket service.
void main() {
  MoorPlugin(PhysicalResourceProvider.INSTANCE).start(WebSocketPluginServer());
}
