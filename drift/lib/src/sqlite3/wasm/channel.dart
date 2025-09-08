import 'dart:js_interop';

import 'package:stream_channel/stream_channel.dart';

import 'package:web/web.dart' as web;

import '../../connections/remote/protocol.dart';
import '../../connections/remote/web_protocol.dart';
import 'setup/protocol.dart';

/// Extension to transform a raw [web.MessagePort] from web workers into a Dart
/// [StreamChannel].
extension WebPortToChannel on web.MessagePort {
  static const _disconnectMessage = '_disconnect';

  /// Converts this port to a two-way communication channel, exposed as a
  /// [StreamChannel].
  ///
  /// This can be used to implement a remote database connection over service
  /// workers.
  ///
  StreamChannel<ProtocolMessage?> channel({
    int nativeSerializionVersion = 0,
  }) {
    final controller = StreamChannelController<ProtocolMessage>();
    final protocol = WebProtocol(
        version: ProtocolVersion.negotiate(nativeSerializionVersion));

    onmessage = (web.MessageEvent event) {
      final message = event.data;

      if (message == _disconnectMessage.toJS) {
        // Other end has closed the connection
        controller.local.sink.close();
      } else {
        controller.local.sink.add(protocol.deserialize(message as JSArray));
      }
    }.toJS;

    controller.local.stream.listen((e) {
      final serialized = protocol.serialize(e);
      postMessage(serialized);
    }, onDone: () {
      // Closed locally, inform the other end.
      postMessage(_disconnectMessage.toJS);

      close();
    });

    return controller.foreign;
  }
}
