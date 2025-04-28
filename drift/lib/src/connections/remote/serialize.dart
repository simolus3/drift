import 'dart:convert';

import 'package:drift/drift.dart';
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
    const serializer = ProtocolMessageSerializer();

    return switch (serialize) {
      false => cast(),
      true => transform(StreamChannelTransformer.fromCodec(serializer)),
    };
  }
}

/// A [Codec] implementation mapping [ProtocolMessage]s to objects that can be
/// serialized through ports across different isolate groups.
class ProtocolMessageSerializer extends Codec<ProtocolMessage, Object?> {
  /// @nodoc
  const ProtocolMessageSerializer();

  @override
  Converter<Object?, ProtocolMessage> get decoder =>
      const _ProtocolMessageDecoder();

  @override
  Converter<ProtocolMessage, Object> get encoder =>
      const _ProtocolMessageEncoder();
}

const _tag_SimpleResponse = 0;
const _tag_ErrorResponse = 1;
const _tag_CancelledResponse = 3;
const _tag_NotifySessionClosed = 4;
const _tag_NotifyTablesUpdated = 5;
const _tag_ClientInitialize = 6;
const _tag_ShutdownServerRequest = 7;
const _tag_StartExclusiveRequest = 8;
const _tag_BeginTransactionRequest = 9;
const _tag_GetSchemaVersionRequest = 10;
const _tag_SchemaVersionResponse = 11;
const _tag_WriteSchemaVersion = 12;
const _tag_CloseSessionRequest = 13;
const _tag_SessionDetails = 14;

/// A converter that implements [startChunkedConversion] through [convert].
abstract base class _StatelessConverter<S, T> extends Converter<S, T> {
  const _StatelessConverter();

  @override
  Sink<S> startChunkedConversion(Sink<T> sink) {
    return _StatelessConverterSink(this, sink);
  }
}

final class _ProtocolMessageEncoder
    extends _StatelessConverter<ProtocolMessage, Object> {
  const _ProtocolMessageEncoder();

  @override
  Object convert(ProtocolMessage input) {
    return switch (input) {
      SimpleResponse() => [_tag_SimpleResponse, input.requestId],
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
      ExecuteResponse() => throw UnimplementedError(),
      StartExclusiveRequest() => [
          _tag_StartExclusiveRequest,
          input.id,
          input.parentId
        ],
      BeginTransactionRequest() => [
          _tag_BeginTransactionRequest,
          input.id,
          input.parentId,
          null,
        ],
      GetSchemaVersion() => [
          _tag_GetSchemaVersionRequest,
          input.id,
          input.sessionId,
        ],
      WriteSchemaVersion() => [
          _tag_WriteSchemaVersion,
          input.id,
          input.sessionId,
          input.schemaVersion
        ],
      CloseSessionRequest() => [
          _tag_CloseSessionRequest,
          input.id,
          input.sessionId,
          input.mode.index
        ],
      ShutdownServerRequest() => [_tag_ShutdownServerRequest, input.id],
      SchemaVersionResponse() => [
          _tag_SchemaVersionResponse,
          input.requestId,
          input.schemaVersion
        ],
      SessionDetails() => [
          _tag_SessionDetails,
          input.requestId,
          input.sessionId,
          input.isRoot,
          input.isDriftTransactionParent,
          input.isTransaction,
          input.isDriftSessionWithInternalLocks,
        ],
    };
  }
}

final class _ProtocolMessageDecoder
    extends _StatelessConverter<Object?, ProtocolMessage> {
  const _ProtocolMessageDecoder();

  @override
  ProtocolMessage convert(Object? input) {
    final [tag, ...payload] = input as List;

    switch (tag) {
      case _tag_SimpleResponse:
        return SimpleResponse(payload[0] as int);
      case _tag_ErrorResponse:
        return ErrorResponse(
          payload[1] as int,
          payload[2] as String,
          switch (payload[3]) {
            null => null,
            final trace as String => StackTrace.fromString(trace),
          },
        );
      case _tag_CancelledResponse:
        return CancelledResponse(payload[0] as int);
      case _tag_NotifySessionClosed:
        return NotifySessionClosed(sessionId: payload[0] as int);
      case _tag_ClientInitialize:
        return ClientInitialize(payload[0] as int);
      case _tag_ShutdownServerRequest:
        return ShutdownServerRequest(payload[0] as int);
      case _tag_StartExclusiveRequest:
        return StartExclusiveRequest(payload[0] as int,
            parentId: payload[1] as int);
      case _tag_BeginTransactionRequest:
        assert(payload[2] == null);
        return BeginTransactionRequest(payload[0] as int,
            parentId: payload[1] as int, options: TransactionOptions());
      case _tag_GetSchemaVersionRequest:
        return GetSchemaVersion(payload[0] as int,
            sessionId: payload[1] as int);
      case _tag_SchemaVersionResponse:
        return SchemaVersionResponse(payload[0] as int, payload[1] as int);
      case _tag_WriteSchemaVersion:
        return WriteSchemaVersion(
          payload[0] as int,
          sessionId: payload[1] as int,
          schemaVersion: payload[2] as int,
        );
      case _tag_SessionDetails:
        return SessionDetails(
          payload[0] as int,
          sessionId: payload[1] as int,
          isRoot: payload[2] as bool,
          isDriftTransactionParent: payload[3] as bool,
          isTransaction: payload[4] as bool,
          isDriftSessionWithInternalLocks: payload[5] as bool,
        );
      default:
        throw ArgumentError.value(tag, 'tag', 'Unknown message type');
    }
  }
}

final class _StatelessConverterSink<S, T> implements Sink<S> {
  final Converter<S, T> _converter;
  final Sink<T> _inner;

  _StatelessConverterSink(this._converter, this._inner);

  @override
  void add(S data) => _inner.add(_converter.convert(data));

  @override
  void close() => _inner.close();
}
