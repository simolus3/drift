import 'dart:convert';

import 'package:stream_channel/stream_channel.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:async';


class MqttStream extends StreamChannelMixin<Object?> {
  late MqttClient _client;
  final StreamController<Object?> _controller;
  late StreamSink<Object?> _sink;

  MqttStream(this._client, String pubTopic, String subTopic, {bool sync = false})      :
        _controller = StreamController<Object?>(sync: sync,
        onCancel: (){
          print('${_client.clientIdentifier} closing');
        },
        onListen: () {
          print('${_client.clientIdentifier} listening');
        },
        onPause: (){
          print('${_client.clientIdentifier} paused');
        },
        onResume: () {
          print('${_client.clientIdentifier} resumed');
        })
  {
    _sink = StreamSinkWrapper(pubTopic, _client, _controller);
    _client.onConnected = () {
      print('${_client.clientIdentifier} connected');
      _client.subscribe(subTopic, MqttQos.exactlyOnce);
      _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
            message.payload.message);
        print('${_client.clientIdentifier} received from ${c[0].topic} with ${jsonDecode(payload)}');
        // Future.delayed(Duration(seconds: 1),() => _controller.add(jsonDecode(payload)));
        _controller.add(jsonDecode(payload));
      });
    };
    _client.connect();
  }

  @override
  StreamSink<Object?> get sink => _sink;

  @override
  Stream<Object?> get stream => _controller.stream;

  factory MqttStream.withGuarantees(Stream<Object?> stream, StreamSink<Object?> sink, {bool allowSinkErrors = true}) {
    final channel = StreamChannel.withGuarantees(stream, sink, allowSinkErrors: allowSinkErrors);
    return MqttStream._internal(channel.sink);
  }

  MqttStream._internal(this._sink):_controller = StreamController<Object?>(sync: true);



}

// /// A class that exposes only the [StreamSink] interface of an object.
// class _StreamSinkWrapper<T> implements StreamSink<T> {
//   final StreamController _target;
//   _StreamSinkWrapper(this._target);
//   void add(T data) {
//     _target.add(data);
//   }
//
//   void addError(Object error, [StackTrace? stackTrace]) {
//     _target.addError(error, stackTrace);
//   }
//
//   Future close() => _target.close();
//
//   Future addStream(Stream<T> source) => _target.addStream(source);
//
//   Future get done => _target.done;
// }

class StreamSinkWrapper implements StreamSink<Object?> {
  final String topic;
  final MqttClient _client;
  final StreamController _target;
  StreamSinkWrapper(this.topic, this._client, this._target);

  @override
  Future<void> add(Object? event) async {
    if (_client.connectionStatus?.state == MqttConnectionState.disconnected) {
      if((await _client.connect())?.state != MqttConnectionState.connected){
        throw StateError('Connection not connected');
      }
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(event));
    print('${_client.clientIdentifier} is sending to $topic with ${jsonEncode(event)}');
    _client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  @override
  Future<void> close() async {
    print('${_client.clientIdentifier} closing');
    if (!(_client.connectionStatus?.state == MqttConnectionState.disconnected)) {
      _client.disconnect();
    }
    // if (!_done.isCompleted) {
    //   _done.complete();
    // }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    print('${_client.clientIdentifier} error $error');
    if ((_client.connectionStatus?.state == MqttConnectionState.disconnected)) {
      throw StateError('Connection has been closed');
    }
    // You can log the error or handle it as needed
  }

  @override
  Future addStream(Stream<Object?> stream) async {
    if (_client.connectionStatus?.state == MqttConnectionState.disconnected) {
      if((await _client.connect())?.state != MqttConnectionState.connected){
        throw StateError('Connection not connected');
      }
    }
    print('${_client.clientIdentifier} stream added');
    await for (var event in stream) {
      await add(event);
    }
  }

  @override
  Future get done => _target.done;
}

class MqttStreamController implements StreamController<Object?> {
  final StreamController<Object?> _controller;
  final MqttClient _client;

  MqttStreamController(String broker, String clientId, {this.onCancel,this.onListen, this.onPause, this.onResume})
      : _client = MqttClient(broker, clientId),
        _controller = StreamController<Object?>(onCancel: onCancel, onListen: onListen, onPause: onPause, onResume: onResume)

  {
    _client.logging(on: false);
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
    // _client.onUnsubscribed = _onUnsubscribed;
    _client.onSubscribeFail = _onSubscribeFail;
    _client.pongCallback = _pong;
  }

  Future<void> connect() async {
    await _client.connect();
  }

  Future<void> subscribe(String topic) async {
    _client.subscribe(topic, MqttQos.atMostOnce);
    // _client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    //   final MqttPublishMessage message = c[0].payload;
    //   _controller.add(message.payload.message);
    // });
  }

  @override
  StreamSubscription<Object?> listen(
      void Function(Object? event)? onData,
      {Function? onError,
        void Function()? onDone,
        bool? cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  // Remaining StreamController methods delegate to _controller
  // ...

  // MQTT client callbacks
  void _onConnected() => print('Connected');
  void _onDisconnected() => print('Disconnected');
  void _onSubscribed(String topic) => print('Subscribed to $topic');
  void _onUnsubscribed(String topic) => print('Unsubscribed from $topic');
  void _onSubscribeFail(String topic) => print('Failed to subscribe to $topic');
  void _pong() => print('Ping response received');

  @override
  FutureOr<void> Function()? onCancel;

  @override
  void Function()? onListen;

  @override
  void Function()? onPause;

  @override
  void Function()? onResume;

  @override
  Future<void> add(Object? event) async {
    if (_client.connectionStatus?.state == MqttConnectionState.disconnected) {
      if((await _client.connect())?.state != MqttConnectionState.connected){
    throw StateError('Connection not connected');
    }
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(event));
    print('${_client.clientIdentifier} is sending to $topic with ${jsonEncode(event)}');
    _client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    // TODO: implement addError
  }

  @override
  Future addStream(Stream<Object?> source, {bool? cancelOnError}) {
    // TODO: implement addStream
    throw UnimplementedError();
  }

  @override
  Future close() async {
    print('${_client.clientIdentifier} closing');
    if (!(_client.connectionStatus?.state == MqttConnectionState.disconnected)) {
      _client.disconnect();
    }
    // if (!_done.isCompleted) {
    //   _done.complete();
    // }
  }

  @override
  // TODO: implement done
  Future get done => throw UnimplementedError();

  @override
  // TODO: implement hasListener
  bool get hasListener => throw UnimplementedError();

  @override
  // TODO: implement isClosed
  bool get isClosed => throw UnimplementedError();

  @override
  // TODO: implement isPaused
  bool get isPaused => throw UnimplementedError();

  @override
  // TODO: implement sink
  StreamSink<Object?> get sink => throw UnimplementedError();

  @override
  // TODO: implement stream
  Stream<Object?> get stream => throw UnimplementedError();
}


