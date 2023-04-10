import 'dart:html';

import 'package:stream_channel/stream_channel.dart';

/// Extension to transform a raw [MessagePort] from web workers into a Dart
/// [StreamChannel].
extension PortToChannel on MessagePort {
  /// Converts this port to a two-way communication channel, exposed as a
  /// [StreamChannel].
  ///
  /// This can be used to implement a remote database connection over service
  /// workers.
  StreamChannel<Object?> channel() {
    final controller = StreamChannelController();
    onMessage.map((event) => event.data).pipe(controller.local.sink);
    controller.local.stream.listen(postMessage, onDone: close);

    return controller.foreign;
  }
}
