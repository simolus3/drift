import 'dart:js_interop';

import 'package:stream_channel/stream_channel.dart';

import 'package:web/web.dart' as web;

import '../remote/protocol.dart';
import '../remote/web_protocol.dart';
import 'wasm_setup/protocol.dart';

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
  /// The [explicitClose] parameter can be used to control whether a close
  /// message should be sent through the channel when it is closed. This will
  /// cause it to be closed on the other end as well. Note that this is not a
  /// reliable way of determining channel closures though, as there is no event
  /// for channels being closed due to a tab or worker being closed.
  /// Both "ends" of a JS channel calling [channel] on their part must use the
  /// value for [explicitClose].
  ///
  /// When [webNativeSerialization] is enabled, the [StreamChannel] can only be
  /// used for drift databases using the `package:drift/remote.dart` protocol
  /// and is not suitable for any other message.
  /// This allows disabling the `serialize` parameter on [connectToRemoteAndInitialize]
  /// and improves performance. Both endpoints need to use the same values for
  /// [explicitClose], [webNativeSerialization] and [nativeSerializionVersion].
  StreamChannel<Object?> channel({
    bool explicitClose = false,
    bool webNativeSerialization = false,
    int nativeSerializionVersion = 0,
  }) {
    final controller = StreamChannelController<Object?>();
    final protocol =
        WebProtocol(ProtocolVersion.negotiate(nativeSerializionVersion));

    onmessage = (web.MessageEvent event) {
      final message = event.data;

      if (explicitClose && message == _disconnectMessage.toJS) {
        // Other end has closed the connection
        controller.local.sink.close();
      } else if (webNativeSerialization) {
        controller.local.sink.add(protocol.deserialize(message as JSArray));
      } else {
        controller.local.sink.add(message.dartify());
      }
    }.toJS;

    controller.local.stream.listen((e) {
      if (webNativeSerialization) {
        final serialized = protocol.serialize(e as Message);
        postMessage(serialized);
      } else {
        postMessage(e.jsify());
      }
    }, onDone: () {
      // Closed locally, inform the other end.
      if (explicitClose) {
        postMessage(_disconnectMessage.toJS);
      }

      close();
    });

    return controller.foreign;
  }
}
