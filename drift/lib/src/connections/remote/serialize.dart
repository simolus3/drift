import 'dart:convert';

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
      true => transform(StreamChannelTransformer.fromCodec(
          const ProtocolMessageSerializer())),
    };
  }
}

/// A [Codec] implementation mapping [ProtocolMessage]s to objects that can be
/// serialized through ports across different isolate groups.
class ProtocolMessageSerializer extends Codec<ProtocolMessage, Object> {
  /// @nodoc
  const ProtocolMessageSerializer();

  @override
  Converter<Object, ProtocolMessage> get decoder =>
      const _ProtocolMessageDecoder();

  @override
  Converter<ProtocolMessage, Object> get encoder =>
      const _ProtocolMessageEncoder();
}

const _tag_Response = 0;
const _tag_ErrorResponse = 1;
const _tag_CancelledResponse = 3;
const _tag_NotifySessionClosed = 4;
const _tag_NotifyTablesUpdated = 5;
const _tag_ClientInitialize = 6;

final class _ProtocolMessageEncoder extends Converter<ProtocolMessage, Object> {
  const _ProtocolMessageEncoder();

  @override
  Object convert(ProtocolMessage input) {
    return switch (input) {
      Response() => [_tag_Response, input.requestId],
      ErrorResponse() => [
          _tag_ErrorResponse,
          input.requestId,
          input.error.toString(),
          input.stackTrace?.toString(),
        ],
      CancelledResponse() => [_tag_CancelledResponse, input.requestId],
      NotifySessionClosed() => [_tag_NotifySessionClosed, input.sessionId],
      NotifyTablesUpdated() => [
          _tag_NotifyTablesUpdated,
          [
            for (final update in input.updates)
              [
                update.table,
                update.kind?.index,
              ]
          ]
        ],
      ClientInitialize() => [_tag_ClientInitialize, input.id],
      // TODO: Handle this case.
      ExecuteRequest() => throw UnimplementedError(),
      // TODO: Handle this case.
      ExecuteBatchRequest() => throw UnimplementedError(),
      // TODO: Handle this case.
      StartExclusiveRequest() => throw UnimplementedError(),
      // TODO: Handle this case.
      BeginTransactionRequest() => throw UnimplementedError(),
      // TODO: Handle this case.
      GetSchemaVersion() => throw UnimplementedError(),
      // TODO: Handle this case.
      WriteSchemaVersion() => throw UnimplementedError(),
      // TODO: Handle this case.
      CloseSessionRequest() => throw UnimplementedError(),
      // TODO: Handle this case.
      ShutdownServerRequest() => throw UnimplementedError(),
    };
  }
}

final class _ProtocolMessageDecoder extends Converter<Object, ProtocolMessage> {
  const _ProtocolMessageDecoder();

  @override
  ProtocolMessage convert(Object input) {
    // TODO: implement convert
    throw UnimplementedError();
  }
}
