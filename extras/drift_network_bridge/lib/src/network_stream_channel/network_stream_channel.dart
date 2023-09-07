import 'dart:async';
import 'dart:convert';
import 'package:stream_channel/stream_channel.dart';

// ignore: implementation_imports
import 'package:drift/src/remote/protocol.dart';
import 'package:meta/meta.dart';

import '../../dev/logging.dart';

const _protocol = DriftProtocol();

//1. The stream is single-subscription, and must follow all the guarantees of single-subscription streams.
//   StreamController is single-subscription by default.
//2. Closing the sink causes the stream to close before it emits any more events.
//   close() of sink calls disconnect() of client which triggers the will message
//   .withWillTopic('$topic/close')
//   .withWillMessage('close')
//3. After the stream closes, the sink is automatically closed. If this happens, sink methods should silently drop their arguments until sink.close is called.
//   StreamSinkWrapper close() calls _onClose which calls _controller.close()
//4. If the stream closes before it has a listener, the sink should silently drop events if possible.
//   _controller.hasListener?_controller.add(decoded):print('No listener');
//5. Canceling the stream's subscription has no effect on the sink. The channel must still be able to respond to the other endpoint closing the channel even after the subscription has been canceled.
//   sounds like we should not do anything on unSubscription and we are
//6. The sink either forwards errors to the other endpoint or closes as soon as an error is added and forwards that error to the sink.done future.
//     void addError(Object error, [StackTrace? stackTrace]) if (allowSinkErrors) forward it, else controller add error
//           if (!allowSinkErrors && sCloseTopic.matches(pubTopic)) {
//           _controller.close();
//         }
//         if (allowSinkErrors && sErrorTopic.matches(pubTopic)) {
//           final payload = jsonDecode(message.payload.toString());
//           _controller.addError(payload['error'], payload['stackTrace']);
//         }

abstract class NetworkClient {
  late final NetworkStreamChannel streamChannel;

  bool get isConnected;

  void add(String event);

  void addError(String serializedError);

  void close();

  void channelRequestStrategy([dynamic s]);

  @mustCallSuper
  void onConnected() {
    streamChannel.onConnected?.call(this);
    startListening();
  }

  Future<void> connect();

  void startListening();

  void disconnect();

  FutureOr<bool> reconnect();
}

class NetworkStreamChannel extends StreamChannelMixin<Object?> {
  final bool allowSinkErrors;
  final Duration connectTimeoutPeriod;
  Completer<void> _closeCompleter = Completer<void>();
  final NetworkClient _client;
  StreamController<Object?> _controller;
  late StreamSinkWrapper _sink;
  void Function(NetworkClient client)? onConnected;

  NetworkStreamChannel(this._client,
      {this.allowSinkErrors = true,
      this.connectTimeoutPeriod = const Duration(seconds: 5)})
      : _controller = StreamController<Object?>() {
    _sink = StreamSinkWrapper(this, allowSinkErrors: allowSinkErrors);
    _client.streamChannel = this;
  }

  // factory NetworkStreamChannel.hostWithGuarantees(NetworkClient client) =>
  //    NetworkStreamChannel(client,allowSinkErrors: false);
  //
  // factory NetworkStreamChannel.clientWithGuarantees(NetworkClient client) =>
  //     NetworkStreamChannel(client,allowSinkErrors: true);

  @override
  Stream<Object?> get stream => _controller.stream;

  @override
  StreamSink<Object?> get sink => _sink;

  Future<void> get done => _controller.done;

  void channelRequestStrategy([dynamic s]) {
    _client.channelRequestStrategy(s);
  }

  Future<void> connect() async {
    return _client.connect();
  }

  void handleDriftMessage(String payload) {
    Object decoded = jsonDecode(payload);
    if (decoded is List && decoded.last == 's') {
      decoded = _protocol.deserialize(decoded);
    }
    _controller.hasListener
        ? _controller.add(decoded)
        : kDebugPrint('No listener');
    return;
  }

  void handleCloseMessage(String payload) {
    if (allowSinkErrors) {
      _sink.close();
      return;
    }
    _closeCompleter.complete();
  }

  void handleError(String error) {
    if (!allowSinkErrors) {
      final payload = jsonDecode(error);
      _controller.addError(payload['error'], payload['stackTrace']);
      return;
    }
  }

  void closeCompleted() {
    if (!_closeCompleter.isCompleted) {
      _closeCompleter.complete();
    }
  }
}

class StreamSinkWrapper implements StreamSink<Object?> {
  final NetworkStreamChannel _channel;
  final bool allowSinkErrors;

  NetworkClient get _client => _channel._client;

  StreamController<Object?> get _controller => _channel._controller;

  set _controller(StreamController<Object?> value) =>
      _channel._controller = value;

  Completer<void> get closeCompleter => _channel._closeCompleter;

  set closeCompleter(Completer<void> value) => _channel._closeCompleter = value;

  FutureOr<void> Function()? _onClose;

  StreamSinkWrapper(this._channel, {this.allowSinkErrors = true});

  static int counter = 0;

  @override
  void add(Object? event) async {
    if (event is Message) {
      event = _protocol.serialize(event);
      if (event != null && event is List) {
        event.add('s');
      }
    }
    if (!_client.isConnected) {
      if (!await _client.reconnect()) {
        throw Exception('Could not reconnect');
      }
    }
    _client.add(jsonEncode(event));
  }

  @override
  Future<void> addError(Object error, [StackTrace? stackTrace]) async {
    if (allowSinkErrors) {
      if (!_client.isConnected) {
        if (!await _client.reconnect()) {
          throw Exception('Could not reconnect');
        }
      }
      _client.addError(jsonEncode(
          {'error': error.toString(), 'stackTrace': stackTrace.toString()}));
    } else {
      _controller.addError(error, stackTrace);
    }
  }

  @override
  Future<void> addStream(Stream<Object?> stream) async {
    await for (var event in stream) {
      add(event);
    }
  }

  @override
  Future<void> close() async {
    _client.close();
    await _onClose?.call();
    await _controller.close();
    _controller = StreamController<Object?>(); // Reset controller for next time
    int timeout = 0;
    while (timeout++ < (_channel.connectTimeoutPeriod.inMilliseconds / 100) &&
        !closeCompleter.isCompleted) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    closeCompleter = Completer<void>(); // Reset completer for next time
  }

  @override
  Future<void> get done => _controller.done;
}
