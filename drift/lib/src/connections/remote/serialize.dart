// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:drift/src/dialect/sqlite/dialect.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:sqlite3/common.dart' as sqlite;

import '../sqlite3/connection.dart';
import 'protocol.dart';

/// Utility to convert arbitrary [StreamChannel]s to channels of
/// [ProtocolMessage]s.
extension ToProtocolChannel on StreamChannel<Object?> {
  /// Depending on [serialize], casts or serializes this channel so that
  /// [ProtocolMessage]s are sent and received.
  StreamChannel<ProtocolMessage> messageChannel({
    required bool serialize,
    DriftDialect dialect = const SqliteDialect(),
    bool debugLog = false,
  }) {
    final serializer = ProtocolMessageSerializer(dialect);

    final messages = switch (serialize) {
      false => cast<ProtocolMessage>(),
      true => transform(StreamChannelTransformer.fromCodec(serializer)),
    };

    if (debugLog) {
      return messages
          .transformStream(
        StreamTransformer.fromBind(
          (source) => source.map(
            (event) {
              print('[in]: ${event.debugToString()}');
              return event;
            },
          ),
        ),
      )
          .transformSink(
        StreamSinkTransformer.fromHandlers(
          handleData: (msg, sink) {
            print('[out]: ${msg.debugToString()}');
            sink.add(msg);
          },
        ),
      );
    }

    return messages;
  }
}

/// A [Codec] implementation mapping [ProtocolMessage]s to objects that can be
/// serialized through ports across different isolate groups.
class ProtocolMessageSerializer extends Codec<ProtocolMessage, Object?> {
  @override
  Converter<Object?, ProtocolMessage> decoder;
  @override
  Converter<ProtocolMessage, Object> encoder;

  /// @nodoc
  ProtocolMessageSerializer(DriftDialect dialect)
      : decoder = _ProtocolMessageDecoder(),
        encoder = _ProtocolMessageEncoder(dialect);
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
const _tag_ExecuteRequest = 15;
const _tag_ExecuteResponse = 16;
const _tag_ExecuteBatched = 17;

const _tag_BigInt = 'bigint';

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
  final DriftDialect dialect;

  const _ProtocolMessageEncoder(this.dialect);

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
      ExecuteRequest() => [
          _tag_ExecuteRequest,
          input.id,
          input.sessionId,
          input.statement.sql,
          [
            for (final (type, value) in input.statement.variables)
              _encodeDbValue(type.sqlParameterOrNull(dialect, value))
          ],
          input.statement.needsResultSet,
          input.statement.isReadOnly,
        ],
      ExecuteBatchRequest() => [
          _tag_ExecuteBatched,
          input.id,
          input.sessionId,
          input.batch.sql,
          [
            for (final stmt in input.batch.statements)
              [
                stmt.sqlIndex,
                [
                  for (final (type, value) in stmt.info.variables)
                    _encodeDbValue(type.sqlParameterOrNull(dialect, value))
                ],
                stmt.info.needsResultSet,
                stmt.info.isReadOnly,
              ]
          ]
        ],
      ExecuteResponse() => [
          _tag_ExecuteResponse,
          input.requestId,
          for (final result in input.result)
            [
              result.affectedRows,
              result.lastInsertRowId,
              switch (result.resultSet) {
                null => null,
                final rs as SqliteResultSet => [
                    rs.resultSet.columnNames,
                    for (final row in rs.resultSet)
                      [for (final value in row.values) _encodeDbValue(value)]
                  ],
              },
            ]
        ],
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

dynamic _encodeDbValue(dynamic variable) {
  if (variable is List<int> && variable is! Uint8List) {
    return Uint8List.fromList(variable);
  } else if (variable is BigInt) {
    return [_tag_BigInt, variable.toString()];
  } else {
    return variable;
  }
}

Object? _decodeDbValue(Object? wire) {
  if (wire is List) {
    if (wire.length == 2 && wire[0] == _tag_BigInt) {
      return BigInt.parse(wire[1].toString());
    }

    return Uint8List.fromList(wire.cast());
  }
  return wire;
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
          payload[0] as int,
          payload[1] as String,
          switch (payload[2]) {
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
      case _tag_CloseSessionRequest:
        return CloseSessionRequest(
          payload[0] as int,
          sessionId: payload[1] as int,
          mode: CloseMode.values[payload[2] as int],
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
      case _tag_ExecuteRequest:
        return ExecuteRequest(
          payload[0] as int,
          sessionId: payload[1] as int,
          statement: StatementInfo.fromText(
            payload[2] as String,
            variables: [
              for (final entry in payload[3] as List)
                (const _UnknownSqlType(), _decodeDbValue(entry))
            ],
            needsResultSet: payload[4] as bool,
            isReadOnly: payload[5] as bool,
          ),
        );
      case _tag_ExecuteResponse:
        return ExecuteResponse(
          payload[0] as int,
          result: [
            for (final result in payload.skip(1).cast<List>())
              QueryResult(
                affectedRows: result[0] as int?,
                lastInsertRowId: result[1] as int?,
                resultSet: switch (result[2]) {
                  null => null,
                  final encoded as List => SqliteResultSet(
                      resultSet: sqlite.ResultSet(
                        (encoded[0] as List).cast(),
                        null,
                        [
                          for (final row in encoded.skip(1))
                            [for (final col in row as List) _decodeDbValue(col)]
                        ],
                      ),
                    )
                },
              )
          ],
        );
      case _tag_ExecuteBatched:
        final sql = (payload[2] as List).cast<String>();

        return ExecuteBatchRequest(
          payload[0] as int,
          sessionId: payload[1] as int,
          batch: StatementBatch(
            sql: sql,
            statements: [
              for (final entry in (payload[3] as List).cast<List>())
                StatementInBatch(
                  entry[0] as int,
                  StatementInfo.fromText(
                    sql[entry[0] as int],
                    variables: [
                      for (final variable in entry[1] as List)
                        (const _UnknownSqlType(), _decodeDbValue(variable))
                    ],
                    needsResultSet: entry[2] as bool,
                    isReadOnly: entry[3] as bool,
                  ),
                )
            ],
          ),
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

/// We can't transport [SqlType] instances across the serialized protocol, so we
/// apply type conversions before sending and use this [_UnknownSqlType] with
/// the transformed value on the other end.
final class _UnknownSqlType implements SqlType {
  const _UnknownSqlType();

  @override
  Object dartValue(DriftDialect dialect, Object databaseValue) {
    throw UnimplementedError();
  }

  @override
  String sqlLiteral(DriftDialect dialect, Object value) {
    throw UnimplementedError();
  }

  @override
  Object sqlParameter(DriftDialect dialect, Object value) {
    return value;
  }

  @override
  String typeName(DriftDialect dialect) {
    throw UnimplementedError();
  }
}
