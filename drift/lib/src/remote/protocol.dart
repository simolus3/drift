// This is a drift-internal file
// ignore_for_file: constant_identifier_names, public_member_api_docs

import 'package:drift/drift.dart';

class DriftProtocol {
  const DriftProtocol();

  static const _tag_Request = 0;
  static const _tag_Response_success = 1;
  static const _tag_Response_error = 2;
  static const _tag_Response_cancelled = 3;

  static const _tag_NoArgsRequest_getTypeSystem = 0;
  static const _tag_NoArgsRequest_terminateAll = 1;

  static const _tag_ExecuteQuery = 3;
  static const _tag_ExecuteBatchedStatement = 4;
  static const _tag_RunTransactionAction = 5;
  static const _tag_EnsureOpen = 6;
  static const _tag_RunBeforeOpen = 7;
  static const _tag_NotifyTablesUpdated = 8;
  static const _tag_DefaultSqlTypeSystem = 9;
  static const _tag_DirectValue = 10;
  static const _tag_SelectResult = 11;
  static const _tag_RequestCancellation = 12;

  Object? serialize(Message message) {
    if (message is Request) {
      return [
        _tag_Request,
        message.id,
        encodePayload(message.payload),
      ];
    } else if (message is ErrorResponse) {
      return [
        _tag_Response_error,
        message.requestId,
        message.error.toString(),
        message.stackTrace,
      ];
    } else if (message is SuccessResponse) {
      return [
        _tag_Response_success,
        message.requestId,
        encodePayload(message.response),
      ];
    } else if (message is CancelledResponse) {
      return [_tag_Response_cancelled, message.requestId];
    } else {
      return null;
    }
  }

  Message deserialize(Object message) {
    if (message is! List) throw const FormatException('Cannot read message');

    final tag = message[0];
    final id = message[1] as int;

    switch (tag) {
      case _tag_Request:
        return Request(id, decodePayload(message[2]));
      case _tag_Response_error:
        return ErrorResponse(id, message[2] as Object, message[3] as String);
      case _tag_Response_success:
        return SuccessResponse(id, decodePayload(message[2]));
      case _tag_Response_cancelled:
        return CancelledResponse(id);
    }

    throw const FormatException('Unknown tag');
  }

  dynamic encodePayload(dynamic payload) {
    if (payload == null || payload is bool) return payload;

    if (payload is NoArgsRequest) {
      return payload.index;
    } else if (payload is ExecuteQuery) {
      return [
        _tag_ExecuteQuery,
        payload.method.index,
        payload.sql,
        [for (final arg in payload.args) _encodeDbValue(arg)],
        payload.executorId,
      ];
    } else if (payload is ExecuteBatchedStatement) {
      return [
        _tag_ExecuteBatchedStatement,
        payload.stmts.statements,
        for (final arg in payload.stmts.arguments)
          [
            arg.statementIndex,
            for (final value in arg.arguments) _encodeDbValue(value),
          ],
        payload.executorId,
      ];
    } else if (payload is RunTransactionAction) {
      return [
        _tag_RunTransactionAction,
        payload.control.index,
        payload.executorId,
      ];
    } else if (payload is EnsureOpen) {
      return [_tag_EnsureOpen, payload.schemaVersion, payload.executorId];
    } else if (payload is RunBeforeOpen) {
      return [
        _tag_RunBeforeOpen,
        payload.details.versionBefore,
        payload.details.versionNow,
        payload.createdExecutor,
      ];
    } else if (payload is NotifyTablesUpdated) {
      return [
        _tag_NotifyTablesUpdated,
        for (final update in payload.updates)
          [
            update.table,
            update.kind?.index,
          ]
      ];
    } else if (payload is SqlTypeSystem) {
      // assume connection uses SqlTypeSystem.defaultInstance, this can't
      // possibly be encoded.
      return _tag_DefaultSqlTypeSystem;
    } else if (payload is SelectResult) {
      // We can't necessary transport maps, so encode as list
      final rows = payload.rows;
      if (rows.isEmpty) {
        return const [_tag_SelectResult];
      } else {
        // Encode by first sending column names, followed by row data
        final result = <Object?>[_tag_SelectResult];

        final columns = rows.first.keys.toList();
        result
          ..add(columns.length)
          ..addAll(columns);

        result.add(rows.length);
        for (final row in rows) {
          result.addAll(row.values);
        }
        return result;
      }
    } else if (payload is RequestCancellation) {
      return [_tag_RequestCancellation, payload.originalRequestId];
    } else {
      return [_tag_DirectValue, payload];
    }
  }

  dynamic decodePayload(dynamic encoded) {
    if (encoded == null || encoded is bool) return encoded;

    int tag;
    List? fullMessage;

    if (encoded is int) {
      tag = encoded;
    } else {
      fullMessage = encoded as List;
      tag = fullMessage[0] as int;
    }

    int readInt(int index) => fullMessage![index] as int;
    int? readNullableInt(int index) => fullMessage![index] as int?;

    switch (tag) {
      case _tag_NoArgsRequest_getTypeSystem:
        return NoArgsRequest.getTypeSystem;
      case _tag_NoArgsRequest_terminateAll:
        return NoArgsRequest.terminateAll;
      case _tag_ExecuteQuery:
        final method = StatementMethod.values[readInt(1)];
        final sql = fullMessage![2] as String;
        final args = (fullMessage[3] as List).map(_decodeDbValue).toList();
        final executorId = readNullableInt(4);
        return ExecuteQuery(method, sql, args, executorId);
      case _tag_ExecuteBatchedStatement:
        final sql = (fullMessage![1] as List).cast<String>();
        final args = <ArgumentsForBatchedStatement>[];

        for (var i = 2; i < fullMessage.length - 1; i++) {
          final list = fullMessage[i] as List;
          args.add(ArgumentsForBatchedStatement(
              list[0] as int, list.skip(1).toList()));
        }

        final executorId = fullMessage.last as int;
        return ExecuteBatchedStatement(
            BatchedStatements(sql, args), executorId);
      case _tag_RunTransactionAction:
        final control = TransactionControl.values[readInt(1)];
        return RunTransactionAction(control, readNullableInt(2));
      case _tag_EnsureOpen:
        return EnsureOpen(readInt(1), readNullableInt(2));
      case _tag_RunBeforeOpen:
        return RunBeforeOpen(
          OpeningDetails(readNullableInt(1), readInt(2)),
          readInt(3),
        );
      case _tag_DefaultSqlTypeSystem:
        return SqlTypeSystem.defaultInstance;
      case _tag_NotifyTablesUpdated:
        final updates = <TableUpdate>[];
        for (var i = 1; i < fullMessage!.length; i++) {
          final encodedUpdate = fullMessage[i] as List;
          final kindIndex = encodedUpdate[1] as int?;

          updates.add(
            TableUpdate(encodedUpdate[0] as String,
                kind: kindIndex == null ? null : UpdateKind.values[kindIndex]),
          );
        }
        return NotifyTablesUpdated(updates);
      case _tag_SelectResult:
        if (fullMessage!.length == 1) {
          // Empty result set, no data
          return const SelectResult([]);
        }

        final columnCount = readInt(1);
        final columns = fullMessage.sublist(2, 2 + columnCount).cast<String>();
        final rows = readInt(2 + columnCount);

        final result = <Map<String, Object?>>[];
        for (var i = 0; i < rows; i++) {
          final rowOffset = 3 + columnCount + i * columnCount;

          result.add({
            for (var c = 0; c < columnCount; c++)
              columns[c]: fullMessage[rowOffset + c]
          });
        }
        return SelectResult(result);
      case _tag_RequestCancellation:
        return RequestCancellation(readInt(1));
      case _tag_DirectValue:
        return encoded[1];
    }

    throw ArgumentError.value(tag, 'tag', 'Tag was unknown');
  }

  dynamic _encodeDbValue(dynamic variable) {
    if (variable is List<int> && variable is! Uint8List) {
      return Uint8List.fromList(variable);
    } else {
      return variable;
    }
  }

  Object? _decodeDbValue(Object? wire) {
    if (wire is List && wire is! Uint8List) {
      return Uint8List.fromList(wire.cast());
    } else {
      return wire;
    }
  }
}

abstract class Message {}

/// A request sent over a communication channel. It is expected that the other
/// peer eventually answers with a matching response.
class Request extends Message {
  /// The id of this request.
  ///
  /// Ids are generated by the sender, so they are only unique per direction
  /// and channel.
  final int id;

  /// The payload associated with this request.
  final Object? payload;

  Request(this.id, this.payload);

  @override
  String toString() {
    return 'Request (id = $id): $payload';
  }
}

class SuccessResponse extends Message {
  final int requestId;
  final Object? response;

  SuccessResponse(this.requestId, this.response);

  @override
  String toString() {
    return 'SuccessResponse (id = $requestId): $response';
  }
}

class ErrorResponse extends Message {
  final int requestId;
  final Object error;
  final String? stackTrace;

  ErrorResponse(this.requestId, this.error, [this.stackTrace]);

  @override
  String toString() {
    return 'ErrorResponse (id = $requestId): $error at $stackTrace';
  }
}

class CancelledResponse extends Message {
  final int requestId;

  CancelledResponse(this.requestId);

  @override
  String toString() {
    return 'Previous request $requestId was cancelled';
  }
}

/// A request without further parameters
enum NoArgsRequest {
  /// Sent from the client to the server. The server will reply with the
  /// [SqlTypeSystem] of the connection it's managing.
  getTypeSystem,

  /// Close the background isolate, disconnect all clients, release all
  /// associated resources
  terminateAll,
}

enum StatementMethod {
  custom,
  deleteOrUpdate,
  insert,
  select,
}

/// Sent from the client to run a sql query. The server replies with the
/// result.
class ExecuteQuery {
  final StatementMethod method;
  final String sql;
  final List<dynamic> args;
  final int? executorId;

  ExecuteQuery(this.method, this.sql, this.args, [this.executorId]);

  @override
  String toString() {
    if (executorId != null) {
      return '$method: $sql with $args (@$executorId)';
    }
    return '$method: $sql with $args';
  }
}

/// Requests a previous request to be cancelled.
///
/// Whether this is supported or not depends on the server and its internal
/// state. This request will be immediately be acknowledged with a null
/// response, which does not indicate whether a cancellation actually happened.
class RequestCancellation {
  final int originalRequestId;

  RequestCancellation(this.originalRequestId);

  @override
  String toString() {
    return 'Cancel previous request $originalRequestId';
  }
}

/// Sent from the client to run [BatchedStatements]
class ExecuteBatchedStatement {
  final BatchedStatements stmts;
  final int? executorId;

  ExecuteBatchedStatement(this.stmts, [this.executorId]);
}

enum TransactionControl {
  /// When using [begin], the [RunTransactionAction.executorId] refers to the
  /// executor starting the transaction. The server must reply with an int
  /// representing the created transaction executor.
  begin,
  commit,
  rollback,
}

/// Sent from the client to commit or rollback a transaction
class RunTransactionAction {
  final TransactionControl control;
  final int? executorId;

  RunTransactionAction(this.control, this.executorId);

  @override
  String toString() {
    return 'RunTransactionAction($control, $executorId)';
  }
}

/// Sent from the client to the server. The server should open the underlying
/// database connection, using the [schemaVersion].
class EnsureOpen {
  final int schemaVersion;
  final int? executorId;

  EnsureOpen(this.schemaVersion, this.executorId);

  @override
  String toString() {
    return 'EnsureOpen($schemaVersion, $executorId)';
  }
}

/// Sent from the server to the client when it should run the before open
/// callback.
class RunBeforeOpen {
  final OpeningDetails details;
  final int createdExecutor;

  RunBeforeOpen(this.details, this.createdExecutor);

  @override
  String toString() {
    return 'RunBeforeOpen($details, $createdExecutor)';
  }
}

/// Sent to notify that a previous query has updated some tables. When a server
/// receives this message, it replies with `null` but forwards a new request
/// with this payload to all connected clients.
class NotifyTablesUpdated {
  final List<TableUpdate> updates;

  NotifyTablesUpdated(this.updates);
}

class SelectResult {
  final List<Map<String, Object?>> rows;

  const SelectResult(this.rows);
}
