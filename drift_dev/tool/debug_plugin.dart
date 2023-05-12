import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:args/args.dart';
import 'package:drift_dev/src/backends/plugin/plugin.dart';
import 'package:stream_transform/stream_transform.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption(
      'port',
      abbr: 'p',
      help: 'The port to use when starting the websocket server',
      defaultsTo: '9999',
    );
  final results = parser.parse(args);

  final port = int.tryParse(results['port'] as String);
  if (port == null) {
    print('Port must be an int');
    print(parser.usage);
    return;
  }

  DriftPlugin.forProduction().start(_WebSocketPluginServer(port: port));
}

class _WebSocketPluginServer implements PluginCommunicationChannel {
  final dynamic address;
  final int port;

  late HttpServer server;

  WebSocket? _currentClient;
  final StreamController<WebSocket?> _clientStream =
      StreamController.broadcast();

  _WebSocketPluginServer({dynamic address, this.port = 9999})
      : address = address ?? InternetAddress.loopbackIPv4 {
    _init();
  }

  Future<void> _init() async {
    server = await HttpServer.bind(address, port);
    print('listening on $address at port $port');
    server.transform(WebSocketTransformer()).listen(_handleClientAdded);
  }

  void _handleClientAdded(WebSocket socket) {
    var client = _currentClient;

    if (client != null) {
      print('ignoring connection attempt because an active client already '
          'exists');
      socket.close();
    } else {
      print('client connected');
      client = _currentClient = socket;
      _clientStream.add(client);
      client.done.then((_) {
        print('client disconnected');
        _currentClient = null;
        _clientStream.add(null);
      });
    }
  }

  @override
  void close() {
    server.close(force: true);
  }

  @override
  void listen(void Function(Request request) onRequest,
      {Function? onError, void Function()? onDone}) {
    final stream = _clientStream.stream;

    // wait until we're connected
    stream.whereType<WebSocket>().first.then((socket) {
      socket.listen((data) {
        print('I: $data');
        onRequest(Request.fromJson(
            json.decode(data as String) as Map<String, dynamic>));
      });
    });
    stream.firstWhere((socket) => socket == null).then((_) => onDone?.call());
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
