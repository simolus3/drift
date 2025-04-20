import 'package:stream_channel/stream_channel.dart';

import 'protocol.dart';

/// Utility to convert arbitrary [StreamChannel]s to channels of
/// [ProtocolMessage]s.
extension ToProtocolChannel on StreamChannel<Object?> {
  /// Depending on [serialize], casts or serializes this channel so that
  /// [ProtocolMessage]s are sent and received.
  StreamChannel<ProtocolMessage> messageChannel({
    required bool serialize,
    bool debugLog = false,
  }) {
    return switch (serialize) {
      false => cast(),
      true => throw 'todo: serialize',
    };
  }
}
