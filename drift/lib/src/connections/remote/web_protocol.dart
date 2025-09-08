/// This is a variant of `serialize.dart` that, instead of serializing to simple
/// values (e.g. strings, numbers, blobs and list thereof), serializes to
/// `JSObject`s.
///
/// This has a a few advantages, like avoiding an expensive `jsify`/`dartify`
/// call afterwards as well a more efficient transport of byte data. Finally, we
/// have a different encoding for [int] and [double] values that ensures they're
/// preserved, which is not possible with the default translation on the web.
// ignore_for_file: constant_identifier_names
@internal
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart' show SqliteException;

import '../../sqlite3/wasm/setup/protocol.dart';
import '../result_set.dart';
import 'protocol.dart';

@JS()
@anonymous
extension type _SerializedSelectResult._(JSObject inner) implements JSObject {
  external factory _SerializedSelectResult(
      {required JSArray<JSString> c, required JSArray<JSArray<JSAny?>> r});

  external JSArray<JSString> get c;
  external JSArray<JSArray<JSAny?>> get r;
}

/// A version of the drift protocol that directly serializes to [JSAny] types,
/// avoiding the intermediate steps first of serializing to simple Dart
/// structures and then using `jsify()`.
final class WebProtocol {
  static const _tag_SimpleResponse = 0;
  static const _tag_ErrorResponse = 1;
  static const _tag_CancelledResponse = 3;
  static const _tag_NotifySessionClosed = 4;
  static const _tag_NotifyTablesUpdated = 5;
  static const _tag_ClientInitialize = 6;
  static const _tag_ShutdownServerRequest = 7;
  static const _tag_StartExclusiveRequest = 8;
  static const _tag_BeginTransactionRequest = 9;
  static const _tag_GetSchemaVersionRequest = 10;
  static const _tag_SchemaVersionResponse = 11;
  static const _tag_WriteSchemaVersion = 12;
  static const _tag_CloseSessionRequest = 13;
  static const _tag_SessionDetails = 14;
  static const _tag_ExecuteRequest = 15;
  static const _tag_ExecuteResponse = 16;
  static const _tag_ExecuteBatched = 17;
  static const _tag_ErrorSqliteException = 18;

  static const _tag_Double = 0;
  static const _tag_BigInt = 1;

  final ProtocolVersion _protocolVersion;

  /// Creates the default instance for [WebProtocol].
  const WebProtocol({ProtocolVersion version = ProtocolVersion.v5})
      : _protocolVersion = version;

  /// Serializes [ProtocolMessage] into a JavaScript representation that is
  /// forwards-compatible with future drift versions.
  JSArray serialize(ProtocolMessage message) {
    final (tag, payload) = switch (message) {
      ExecuteRequest() => (
          _tag_ExecuteRequest,
          <JSAny?>[
            message.id.toJS,
            message.sessionId.toJS,
            message.statement.sql.toJS,
            [
              for (final variable in message.statement.variables)
                _encodeDbValue(variable.rawValue)
            ].toJS,
            message.statement.needsResultSet.toJS,
            message.statement.isReadOnly.toJS,
          ].toJS,
        ),
      ExecuteBatchRequest() => (
          _tag_ExecuteBatched,
          <JSAny>[
            message.id.toJS,
            message.sessionId.toJS,
            [for (final sql in message.batch.sql) sql.toJS].toJS,
            [
              for (final stmt in message.batch.statements)
                [
                  stmt.sqlIndex.toJS,
                  [
                    for (final variable in stmt.info.variables)
                      _encodeDbValue(variable.rawValue)
                  ].toJS,
                  stmt.info.needsResultSet.toJS,
                  stmt.info.isReadOnly.toJS,
                ].toJS,
            ].toJS
          ].toJS
        ),
      ClientInitialize(:final id) => (_tag_ClientInitialize, id.toJS),
      SessionDetails() => (
          _tag_SessionDetails,
          <JSAny>[
            message.requestId.toJS,
            message.sessionId.toJS,
            message.isRoot.toJS,
            message.isDriftTransactionParent.toJS,
            message.isTransaction.toJS,
            message.isDriftSessionWithInternalLocks.toJS,
          ].toJS
        ),
      StartExclusiveRequest() => (
          _tag_StartExclusiveRequest,
          <JSAny>[message.id.toJS, message.parentId.toJS].toJS
        ),
      BeginTransactionRequest() => (
          _tag_BeginTransactionRequest,
          <JSAny?>[message.id.toJS, message.parentId.toJS, null].toJS,
        ),
      CloseSessionRequest() => (
          _tag_CloseSessionRequest,
          <JSAny?>[
            message.id.toJS,
            message.sessionId.toJS,
            message.mode.name.toJS
          ].toJS,
        ),
      GetSchemaVersion() => (
          _tag_GetSchemaVersionRequest,
          <JSAny?>[message.id.toJS, message.sessionId.toJS].toJS,
        ),
      WriteSchemaVersion() => (
          _tag_GetSchemaVersionRequest,
          <JSAny?>[
            message.id.toJS,
            message.sessionId.toJS,
            message.schemaVersion.toJS
          ].toJS,
        ),
      ShutdownServerRequest(:final id) => (_tag_ShutdownServerRequest, id.toJS),
      NotifySessionClosed(:final sessionId) => (
          _tag_NotifySessionClosed,
          sessionId.toJS
        ),
      NotifyTablesUpdated(:final updates) => (
          _tag_NotifyTablesUpdated,
          [
            for (final update in updates)
              [
                update.table.toJS,
                update.kind?.index.toJS,
              ].toJS
          ].toJS,
        ),
      SimpleResponse(:final requestId) => (_tag_SimpleResponse, requestId.toJS),
      ExecuteResponse() => (
          _tag_ExecuteResponse,
          <JSAny?>[
            message.requestId.toJS,
            <JSAny?>[
              for (final result in message.result)
                <JSAny?>[
                  result.affectedRows?.toJS,
                  result.lastInsertRowId?.toJS,
                  switch (result.resultSet) {
                    null => null,
                    final resultSet => _serializeRawResultSet(resultSet),
                  }
                ].toJS,
            ].toJS,
          ].toJS
        ),
      SchemaVersionResponse() => (
          _tag_SchemaVersionResponse,
          <JSAny?>[message.requestId.toJS, message.schemaVersion.toJS].toJS,
        ),
      ErrorResponse(
        :final requestId,
        error: final SqliteException e,
        :final stackTrace
      ) =>
        (
          _tag_ErrorSqliteException,
          [
            requestId.toJS,
            stackTrace?.toString().toJS,
            e.message.toJS,
            e.explanation?.toJS,
            e.extendedResultCode.toJS,
            e.operation?.toJS,
            e.causingStatement?.toJS,
            switch (e.parametersToStatement) {
              null => null,
              final params => <JSAny?>[
                  for (final parameter in params) _encodeDbValue(parameter),
                ].toJS,
            },
            e.offset?.toJS,
          ].toJS
        ),
      ErrorResponse(:final requestId, :final error, :final stackTrace) => (
          _tag_ErrorResponse,
          [requestId.toJS, error.toString().toJS, stackTrace?.toString().toJS]
              .toJS
        ),
      CancelledResponse(:final requestId) => (
          _tag_CancelledResponse,
          requestId.toJS
        ),
    };

    return [tag.toJS, payload].toJS;
  }

  /// Deserializes a message obtained from [serialize].
  ProtocolMessage deserialize(JSArray message) {
    final [tag, payload] = message.toDart;

    return switch (tag) {
      _tag_ExecuteRequest => _decodeExecuteRequest(payload as JSArray),
      _tag_ExecuteBatched => _decodeExecuteBatchRequest(payload as JSArray),
      _tag_ClientInitialize => ClientInitialize(_int(payload)),
      _tag_SessionDetails => _decodeSessionDetails(payload as JSArray),
      _tag_StartExclusiveRequest =>
        _decodeStartExclusiveRequest(payload as JSArray),
      _tag_BeginTransactionRequest =>
        _decodeBeginTransactionRequest(payload as JSArray),
      _tag_CloseSessionRequest =>
        _decodeCloseSessionRequest(payload as JSArray),
      _tag_GetSchemaVersionRequest =>
        _decodeGetSchemaVersion(payload as JSArray),
      _tag_WriteSchemaVersion => _decodeWriteSchemaVersion(payload as JSArray),
      _tag_ShutdownServerRequest => ShutdownServerRequest(_int(payload)),
      _tag_NotifySessionClosed => NotifySessionClosed(sessionId: _int(payload)),
      _tag_NotifyTablesUpdated =>
        _decodeNotifyTablesUpdated(payload as JSArray),
      _tag_SimpleResponse => SimpleResponse(_int(payload)),
      _tag_ExecuteResponse => _decodeExecuteResponse(payload as JSArray),
      _tag_SchemaVersionResponse =>
        _decodeSchemaVersionResponse(payload as JSArray),
      _tag_ErrorSqliteException =>
        _decodeSqliteExceptionResponse(payload as JSArray),
      _tag_ErrorResponse => _decodeGenericErrorResponse(payload as JSArray),
      _tag_CancelledResponse => CancelledResponse(_int(payload)),
      _ => throw ArgumentError('Unknown message tag $tag'),
    };
  }

  ExecuteRequest _decodeExecuteRequest(JSArray payload) {
    return ExecuteRequest(
      _int(payload[0]),
      sessionId: _int(payload[1]),
      statement: StatementInfo.fromText(
        (payload[2] as JSString).toDart,
        variables: [
          for (final variable in (payload[3] as JSArray).toDart)
            // We don't actually need the type, so this can be anything.
            MappedValue.raw(BuiltinDriftType.text, _decodeDbValue(variable))
        ],
        needsResultSet: (payload[4] as JSBoolean).toDart,
        isReadOnly: (payload[5] as JSBoolean).toDart,
      ),
    );
  }

  ExecuteBatchRequest _decodeExecuteBatchRequest(JSArray payload) {
    final sql =
        (payload[2] as JSArray<JSString>).toDart.map((e) => e.toDart).toList();
    final rawStmts = (payload[3] as JSArray<JSArray>).toDart;
    final stmts = [
      for (final rawStmt in rawStmts)
        StatementInBatch(
          _int(rawStmt[0]),
          StatementInfo.fromText(
            sql[_int(rawStmt[0])],
            variables: [
              for (final variable in (rawStmt[1] as JSArray).toDart)
                // We don't actually need the type, so this can be anything.
                MappedValue.raw(BuiltinDriftType.text, _decodeDbValue(variable))
            ],
            needsResultSet: (rawStmt[2] as JSBoolean).toDart,
            isReadOnly: (rawStmt[3] as JSBoolean).toDart,
          ),
        ),
    ];

    return ExecuteBatchRequest(
      _int(payload[0]),
      sessionId: _int(payload[1]),
      batch: StatementBatch(sql: sql, statements: stmts),
    );
  }

  SessionDetails _decodeSessionDetails(JSArray payload) {
    return SessionDetails(
      _int(payload[0]),
      sessionId: _int(payload[1]),
      isRoot: (payload[2] as JSBoolean).toDart,
      isDriftTransactionParent: (payload[3] as JSBoolean).toDart,
      isTransaction: (payload[4] as JSBoolean).toDart,
      isDriftSessionWithInternalLocks: (payload[5] as JSBoolean).toDart,
    );
  }

  StartExclusiveRequest _decodeStartExclusiveRequest(JSArray payload) {
    return StartExclusiveRequest(_int(payload[0]), parentId: _int(payload[1]));
  }

  BeginTransactionRequest _decodeBeginTransactionRequest(JSArray payload) {
    return BeginTransactionRequest(_int(payload[0]),
        parentId: _int(payload[1]), options: const TransactionOptions());
  }

  CloseSessionRequest _decodeCloseSessionRequest(JSArray payload) {
    return CloseSessionRequest(
      _int(payload[0]),
      sessionId: _int(payload[1]),
      mode: CloseMode.values.byName((payload[2] as JSString).toDart),
    );
  }

  GetSchemaVersion _decodeGetSchemaVersion(JSArray payload) {
    return GetSchemaVersion(_int(payload[0]), sessionId: _int(payload[1]));
  }

  WriteSchemaVersion _decodeWriteSchemaVersion(JSArray payload) {
    return WriteSchemaVersion(_int(payload[0]),
        sessionId: _int(payload[1]), schemaVersion: _int(payload[2]));
  }

  NotifyTablesUpdated _decodeNotifyTablesUpdated(JSArray payload) {
    return NotifyTablesUpdated([
      for (final update in payload.toDart.cast<JSArray>())
        TableUpdate(
          (update[0] as JSString).toDart,
          kind: switch (_nullableInt(update[1])) {
            null => null,
            final index => UpdateKind.values[index],
          },
        )
    ]);
  }

  ExecuteResponse _decodeExecuteResponse(JSArray payload) {
    final rawResults = payload[1] as JSArray;
    final results = [
      for (final result in rawResults.toDart.cast<JSArray>())
        QueryResult(
          affectedRows: _nullableInt(result[0]),
          lastInsertRowId: _nullableInt(result[1]),
          resultSet: switch (result[1]) {
            null => null,
            final other =>
              _deserializeRawResultSet(other as _SerializedSelectResult),
          },
        )
    ];

    return ExecuteResponse(_int(payload[0]), result: results);
  }

  SchemaVersionResponse _decodeSchemaVersionResponse(JSArray payload) {
    return SchemaVersionResponse(_int(payload[0]), _int(payload[1]));
  }

  ErrorResponse _decodeSqliteExceptionResponse(JSArray payload) {
    final message = (payload[2] as JSString).toDart;
    final explanation = _decodeNullableString(payload[3]);
    final extendedResultCode = _int(payload[4]);
    final operation = _decodeNullableString(payload[5]);
    final causingStatement = _decodeNullableString(payload[6]);
    final rawParameters = payload[7] as JSArray<JSAny?>?;
    final offset = _nullableInt(payload[8]);
    final parameters = rawParameters == null
        ? null
        : [for (final value in rawParameters.toDart) _decodeDbValue(value)];

    return ErrorResponse(
      _int(payload[0]),
      SqliteException(
        extendedResultCode,
        message,
        explanation,
        causingStatement,
        parameters,
        operation,
        offset,
      ),
      _decodeStackStrace(payload[1]),
    );
  }

  ErrorResponse _decodeGenericErrorResponse(JSArray payload) {
    return ErrorResponse(
      _int(payload[0]),
      (payload[1] as JSString).toDart,
      _decodeStackStrace(payload[2]),
    );
  }

  _SerializedSelectResult _serializeRawResultSet(RawResultSet result) {
    final columns = result.columnNames.map((e) => e.toJS).toList().toJS;

    if (result.isEmpty) {
      return _SerializedSelectResult(c: columns, r: JSArray());
    } else {
      final rows = <JSArray<JSAny?>>[];
      for (final row in result) {
        final jsRow = <JSAny?>[];

        for (final value in row.values) {
          jsRow.add(_encodeDbValue(value));
        }
        rows.add(jsRow.toJS);
      }

      return _SerializedSelectResult(c: columns, r: rows.toJS);
    }
  }

  RawResultSet _deserializeRawResultSet(_SerializedSelectResult result) {
    final columns = result.c.toDart.map((e) => e.toDart).toList();
    final rawRows = result.r.toDart;
    final columnToIndex =
        Map.fromEntries(columns.mapIndexed((i, name) => MapEntry(name, i)));

    return RawResultSet.generate(rawRows.length, (i, rs) {
      final rawRow = rawRows[0];
      final values = rawRow.toDart.map(_decodeDbValue).toList();

      return RawRow.by(
        resultSet: rs,
        byPosition: (pos) => values[pos.index],
        byName: (name) => values[columnToIndex[name]!],
      );
    }, columnNames: columns);
  }

  JSAny? _encodeDbValue(Object? value) {
    return switch (value) {
      null => null,
      int i => i.toJS,
      bool b => b.toJS,
      String s => s.toJS,
      double d => [_tag_Double.toJS, d.toJS].toJS,
      BigInt i => [_tag_BigInt.toJS, i.toString().toJS].toJS,
      List<int> blob => Uint8List.fromList(blob).toJS,
      _ => throw ArgumentError('Unknown db value: $value'),
    };
  }

  Object? _decodeDbValue(JSAny? value) {
    if (value case final value?) {
      // Not undefined, not null.
      if (value.typeofEquals('number')) {
        // Note that doubles are encoded as list
        return _int(value);
      } else if (value.typeofEquals('boolean')) {
        return (value as JSBoolean).toDart;
      } else if (value.typeofEquals('string')) {
        return (value as JSString).toDart;
      } else if (value.instanceOfString('Uint8Array')) {
        return (value as JSUint8Array).toDart;
      } else {
        final [tag, payload] = (value as JSArray).toDart;
        if (tag.equals(_tag_BigInt.toJS).toDart) {
          return BigInt.parse((payload as JSString).toDart);
        } else {
          return (payload as JSNumber).toDartDouble;
        }
      }
    } else {
      return null;
    }
  }

  String? _decodeNullableString(JSAny? value) {
    return value.isDefinedAndNotNull ? (value as JSString).toDart : null;
  }

  StackTrace? _decodeStackStrace(JSAny? stackTrace) {
    return switch (_decodeNullableString(stackTrace)) {
      var s? => StackTrace.fromString(s),
      _ => null,
    };
  }
}

int _int(JSAny? any) {
  return (any as JSNumber).toDartInt;
}

int? _nullableInt(JSAny? any) {
  return any.isUndefinedOrNull ? null : _int(any);
}
