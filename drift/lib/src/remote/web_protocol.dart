// ignore_for_file: constant_identifier_names
@internal
library;

import 'dart:js_interop';

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import 'protocol.dart';

@JS()
@anonymous
extension type _SerializedRequest._(JSObject inner) implements JSObject {
  external factory _SerializedRequest({required int i, required JSAny? p});

  external int get i;
  external JSAny? get p;
}

@JS()
@anonymous
extension type _SerializedSelectResult._(JSObject inner) implements JSObject {
  external factory _SerializedSelectResult(
      {required JSArray<JSString> c, required JSArray<JSArray<JSAny?>> r});

  external JSArray<JSString> get c;
  external JSArray<JSArray<JSAny?>> get r;
}

/// A version of the [DriftProtocol] that directly serializes to [JSAny] types,
/// avoiding the intermediate steps first of serializing to simple Dart
/// structures and then using `jsify()`.
final class WebProtocol {
  static const _tag_Request = 0;
  static const _tag_SuccessResponse = 1;
  static const _tag_ErrorResponse = 2;
  static const _tag_CancelledResponse = 3;

  static const _tag_NoArgsRequest_terminateAll = 0;

  static const _tag_ExecuteQuery = 3;
  static const _tag_ExecuteBatchedStatement = 4;
  static const _tag_RunTransactionAction = 5;
  static const _tag_EnsureOpen = 6;
  static const _tag_RunBeforeOpen = 7;
  static const _tag_NotifyTablesUpdated = 8;
  static const _tag_RequestCancellation = 12;
  static const _tag_ServerInfo = 13;
  static const _tag_BigInt = 14;
  static const _tag_Double = 15;

  /// Creates the default instance for [WebProtocol].
  const WebProtocol();

  /// Serializes [Message] into a JavaScript representation that is forwards-
  /// compatible with future drift versions.
  JSArray serialize(Message message) {
    final (tag, payload) = switch (message) {
      Request(:final id, :final payload) => (
          _tag_Request,
          _SerializedRequest(i: id, p: _serializeRequest(payload))
        ),
      SuccessResponse(:final requestId, :final response) => (
          _tag_SuccessResponse,
          _SerializedRequest(i: requestId, p: _serializeResponse(response))
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
  Message deserialize(JSArray message) {
    final [tag, payload] = message.toDart;

    Request decodeRequest() {
      final serialized = payload as _SerializedRequest;
      return Request(serialized.i, _deserializeRequest(serialized.p));
    }

    SuccessResponse decodeSuccess() {
      final serialized = payload as _SerializedRequest;
      return SuccessResponse(serialized.i, _deserializeResponse(payload.p));
    }

    return switch (_int(tag)) {
      _tag_Request => decodeRequest(),
      _tag_SuccessResponse => decodeSuccess(),
      _tag_ErrorResponse => _decodeErrorResponse(payload as JSArray),
      _tag_CancelledResponse => CancelledResponse(_int(payload)),
      _ => throw ArgumentError('Unknown message tag $tag'),
    };
  }

  JSAny? _serializeRequest(RequestPayload? payload) {
    return switch (payload) {
      null => null,
      ExecuteQuery() => [
          _tag_ExecuteQuery.toJS,
          payload.method.index.toJS,
          payload.sql.toJS,
          [for (final arg in payload.args) _encodeDbValue(arg)].toJS,
          payload.executorId?.toJS,
        ].toJS,
      RequestCancellation(:final originalRequestId) => [
          _tag_RequestCancellation.toJS,
          originalRequestId.toJS,
        ].toJS,
      ExecuteBatchedStatement() => [
          _tag_ExecuteBatchedStatement.toJS,
          payload.stmts.statements.map((e) => e.toJS).toList().toJS,
          for (final arg in payload.stmts.arguments)
            [
              arg.statementIndex.toJS,
              for (final value in arg.arguments) _encodeDbValue(value),
            ].toJS,
          payload.executorId?.toJS,
        ].toJS,
      RunNestedExecutorControl() => [
          _tag_RunTransactionAction.toJS,
          payload.control.index.toJS,
          payload.executorId?.toJS,
        ].toJS,
      EnsureOpen() => [
          _tag_EnsureOpen.toJS,
          payload.schemaVersion.toJS,
          payload.executorId?.toJS
        ].toJS,
      ServerInfo() => [
          _tag_ServerInfo.toJS,
          payload.dialect.name.toJS,
        ].toJS,
      RunBeforeOpen() => [
          _tag_RunBeforeOpen.toJS,
          payload.details.versionBefore?.toJS,
          payload.details.versionNow.toJS,
          payload.createdExecutor.toJS,
        ].toJS,
      NotifyTablesUpdated() => <JSAny?>[
          _tag_NotifyTablesUpdated.toJS,
          for (final update in payload.updates)
            [
              update.table.toJS,
              update.kind?.index.toJS,
            ].toJS
        ].toJS,
      NoArgsRequest.terminateAll => _tag_NoArgsRequest_terminateAll.toJS,
    };
  }

  RequestPayload? _deserializeRequest(JSAny? payload) {
    if (payload.isUndefinedOrNull) {
      return null;
    }

    if (payload.typeofEquals('number')) {
      // Only terminateAll is encoded as a direct number
      assert(_int(payload) == _tag_NoArgsRequest_terminateAll);
      return NoArgsRequest.terminateAll;
    }

    final dartList = (payload as JSArray).toDart;
    final tag = _int(dartList[0]);

    ExecuteBatchedStatement readBatched() {
      final sqlStatements = (dartList[1] as JSArray<JSString>)
          .toDart
          .map((e) => e.toDart)
          .toList();
      final arguments = dartList.length - 3;
      final args = [
        for (final instantiation in dartList
            .skip(2)
            .take(arguments)
            .cast<JSArray>()
            .map((e) => e.toDart))
          ArgumentsForBatchedStatement(
            _int(instantiation[0]),
            instantiation.skip(1).map(_decodeDbValue).toList(),
          ),
      ];

      return ExecuteBatchedStatement(
        BatchedStatements(sqlStatements, args),
        _nullableInt(dartList[dartList.length - 1]),
      );
    }

    return switch (tag) {
      _tag_ExecuteQuery => ExecuteQuery(
          StatementMethod.values[_int(dartList[1])],
          (dartList[2] as JSString).toDart,
          [
            for (final entry in (dartList[3] as JSArray).toDart)
              _decodeDbValue(entry),
          ],
          _nullableInt(dartList[4])),
      _tag_RequestCancellation => RequestCancellation(_int(dartList[1])),
      _tag_ExecuteBatchedStatement => readBatched(),
      _tag_RunTransactionAction => RunNestedExecutorControl(
          NestedExecutorControl.values[_int(dartList[1])],
          _nullableInt(dartList[2]),
        ),
      _tag_EnsureOpen => EnsureOpen(
          _int(dartList[1]),
          _nullableInt(dartList[2]),
        ),
      _tag_ServerInfo =>
        ServerInfo(SqlDialect.values.byName((dartList[1] as JSString).toDart)),
      _tag_RunBeforeOpen => RunBeforeOpen(
          OpeningDetails(_nullableInt(dartList[1]), _int(dartList[2])),
          _int(dartList[3]),
        ),
      _tag_NotifyTablesUpdated => NotifyTablesUpdated(dartList.skip(1).map((e) {
          final [table, kindOrNull] = (e as JSArray).toDart;

          return TableUpdate((table as JSString).toDart,
              kind: kindOrNull.isUndefinedOrNull
                  ? null
                  : UpdateKind.values[_int(kindOrNull)]);
        }).toList()),
      _ => throw ArgumentError('Unknown request tag $tag'),
    };
  }

  JSAny? _serializeResponse(ResponsePayload? response) {
    return switch (response) {
      null => null,
      PrimitiveResponsePayload(:final message) =>
        message is bool ? message.toJS : (message as int).toJS,
      SelectResult() => _serializeSelectResult(response),
    };
  }

  _SerializedSelectResult _serializeSelectResult(SelectResult result) {
    if (result.rows.isEmpty) {
      return _SerializedSelectResult(c: JSArray(), r: JSArray());
    } else {
      final columns = result.rows.first.keys.map((e) => e.toJS).toList().toJS;
      final rows = <JSArray<JSAny?>>[];
      for (final row in result.rows) {
        final jsRow = <JSAny?>[];

        for (final value in row.values) {
          jsRow.add(_encodeDbValue(value));
        }
        rows.add(jsRow.toJS);
      }

      return _SerializedSelectResult(c: columns, r: rows.toJS);
    }
  }

  ResponsePayload? _deserializeResponse(JSAny? response) {
    if (response.isUndefinedOrNull) {
      return null;
    } else if (response.typeofEquals('boolean')) {
      return PrimitiveResponsePayload.bool((response as JSBoolean).toDart);
    } else if (response.typeofEquals('number')) {
      return PrimitiveResponsePayload.int(_int(response));
    } else {
      final result = response as _SerializedSelectResult;

      final columns = response.c.toDart.map((e) => e.toDart).toList();
      final rows = <Map<String, Object?>>[];
      for (final row in result.r.toDart) {
        final dartRow = <String, Object?>{};
        for (final (i, entry) in row.toDart.indexed) {
          dartRow[columns[i]] = _decodeDbValue(entry);
        }
        rows.add(dartRow);
      }

      return SelectResult(rows);
    }
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

  ErrorResponse _decodeErrorResponse(JSArray array) {
    final [requestId, error, stackTrace] = array.toDart;

    return ErrorResponse(
      _int(requestId),
      (error as JSString).toDart,
      stackTrace.isDefinedAndNotNull
          ? StackTrace.fromString((stackTrace as JSString).toDart)
          : null,
    );
  }
}

int _int(JSAny? any) {
  return (any as JSNumber).toDartInt;
}

int? _nullableInt(JSAny? any) {
  return any.isUndefinedOrNull ? null : _int(any);
}
