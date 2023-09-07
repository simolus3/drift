import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift_network_bridge/src/network_stream_channel/network_stream_channel.dart';


abstract class DatabaseGateway {
  final NetworkStreamChannel Function() _clientFactoryWithGuarantees;

  late DriftServer _server;
  final bool allowRemoteShutdown;
  bool _serving = false;
  Completer _ready = Completer();

  Stream<Object?> Function(Stream<Object?> source)? _changeStream;

  Future<void> get done => _server.done;
  Future<void> get isReady => _ready.future;

  NetworkStreamChannel createConnection() {
    return _clientFactoryWithGuarantees.call();
  }


  DatabaseGateway(this._clientFactoryWithGuarantees, {this.allowRemoteShutdown = false});


  Future<void> serveExecuter(QueryExecutor executor,{bool serialize = true}) async {
    _server = DriftServer(executor, allowRemoteShutdown: allowRemoteShutdown);
    if(_serving){
      throw Exception('Already serving');
    }
    _serving = true;
    completeChannel((NetworkStreamChannel channel) async {
      await channel.connect();
      if(_changeStream != null) {
        channel.changeStream(_changeStream!);
      }
      _server.serve(channel,serialize: serialize);
      if(!_ready.isCompleted) {
        _ready.complete();
      }
    });
  }
  Future<void> serve(GeneratedDatabase db,{bool serialize = true}) async {
    return serveExecuter(db.executor,serialize: serialize);
  }
  // MqttStreamChannel get client => _client;

  Future<void> completeChannel(Future Function(NetworkStreamChannel channel) hostFactoryWithGuarantee);

  void changeStream(Stream<Object?> Function(Stream<Object?> source) checkStreamOfSimple) {
    _changeStream = checkStreamOfSimple;
  }

  Future<void> shutdown() async {
    _ready = Completer();
    return _server.shutdown();
  }
}