part of 'moor_isolate.dart';

// ignore_for_file: constant_identifier_names

class _MoorCodec extends MessageCodec {
  const _MoorCodec();

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

  @override
  dynamic encodePayload(dynamic payload) {
    if (payload == null || payload is bool) return payload;

    if (payload is _NoArgsRequest) {
      return payload.index;
    } else if (payload is _ExecuteQuery) {
      return [
        _tag_ExecuteQuery,
        payload.method.index,
        payload.sql,
        [for (final arg in payload.args) _encodeDbValue(arg)],
        payload.executorId,
      ];
    } else if (payload is _ExecuteBatchedStatement) {
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
    } else if (payload is _RunTransactionAction) {
      return [
        _tag_RunTransactionAction,
        payload.control.index,
        payload.executorId,
      ];
    } else if (payload is _EnsureOpen) {
      return [_tag_EnsureOpen, payload.schemaVersion, payload.executorId];
    } else if (payload is _RunBeforeOpen) {
      return [
        _tag_RunBeforeOpen,
        payload.details.versionBefore,
        payload.details.versionNow,
        payload.createdExecutor,
      ];
    } else if (payload is _NotifyTablesUpdated) {
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
    } else {
      return [_tag_DirectValue, payload];
    }
  }

  @override
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
        return _NoArgsRequest.getTypeSystem;
      case _tag_NoArgsRequest_terminateAll:
        return _NoArgsRequest.terminateAll;
      case _tag_ExecuteQuery:
        final method = _StatementMethod.values[readInt(1)];
        final sql = fullMessage![2] as String;
        final args = (fullMessage[3] as List).map(_decodeDbValue).toList();
        final executorId = readNullableInt(4);
        return _ExecuteQuery(method, sql, args, executorId);
      case _tag_ExecuteBatchedStatement:
        final sql = (fullMessage![1] as List).cast<String>();
        final args = <ArgumentsForBatchedStatement>[];

        for (var i = 2; i < fullMessage.length - 1; i++) {
          final list = fullMessage[i] as List;
          args.add(ArgumentsForBatchedStatement(list[0] as int, [
            for (var j = 1; j < list.length; j++) _decodeDbValue(list[j]),
          ]));
        }

        final executorId = fullMessage.last as int;
        return _ExecuteBatchedStatement(
            BatchedStatements(sql, args), executorId);
      case _tag_RunTransactionAction:
        final control = _TransactionControl.values[readInt(1)];
        return _RunTransactionAction(control, readNullableInt(2));
      case _tag_EnsureOpen:
        return _EnsureOpen(readInt(1), readNullableInt(2));
      case _tag_RunBeforeOpen:
        return _RunBeforeOpen(
          OpeningDetails(readNullableInt(1), readInt(2)),
          readInt(3),
        );
      case _tag_DefaultSqlTypeSystem:
        return SqlTypeSystem.defaultInstance;
      case _tag_NotifyTablesUpdated:
        final updates = <TableUpdate>[];
        for (var i = 1; i < fullMessage!.length; i++) {
          final encodedUpdate = fullMessage[i] as List;
          updates.add(
            TableUpdate(encodedUpdate[0] as String,
                kind: UpdateKind.values[encodedUpdate[1] as int]),
          );
        }
        return _NotifyTablesUpdated(updates);
      case _tag_DirectValue:
        return encoded[1];
    }

    throw ArgumentError.value(tag, 'tag', 'Tag was unknown');
  }

  dynamic _encodeDbValue(dynamic variable) {
    if (variable is List<int>) {
      return TransferableTypedData.fromList([Uint8List.fromList(variable)]);
    } else {
      return variable;
    }
  }

  dynamic _decodeDbValue(dynamic encoded) {
    if (encoded is TransferableTypedData) {
      return encoded.materialize().asUint8List();
    } else {
      return encoded;
    }
  }
}

/// A request without further parameters
enum _NoArgsRequest {
  /// Sent from the client to the server. The server will reply with the
  /// [SqlTypeSystem] of the [_MoorServer.connection] it's managing.
  getTypeSystem,

  /// Close the background isolate, disconnect all clients, release all
  /// associated resources
  terminateAll,
}

enum _StatementMethod {
  custom,
  deleteOrUpdate,
  insert,
  select,
}

/// Sent from the client to run a sql query. The server replies with the
/// result.
class _ExecuteQuery {
  final _StatementMethod method;
  final String sql;
  final List<dynamic> args;
  final int? executorId;

  _ExecuteQuery(this.method, this.sql, this.args, [this.executorId]);

  @override
  String toString() {
    if (executorId != null) {
      return '$method: $sql with $args (@$executorId)';
    }
    return '$method: $sql with $args';
  }
}

/// Sent from the client to run [BatchedStatements]
class _ExecuteBatchedStatement {
  final BatchedStatements stmts;
  final int? executorId;

  _ExecuteBatchedStatement(this.stmts, [this.executorId]);
}

enum _TransactionControl {
  /// When using [begin], the [_RunTransactionAction.executorId] refers to the
  /// executor starting the transaction. The server must reply with an int
  /// representing the created transaction executor.
  begin,
  commit,
  rollback,
}

/// Sent from the client to commit or rollback a transaction
class _RunTransactionAction {
  final _TransactionControl control;
  final int? executorId;

  _RunTransactionAction(this.control, this.executorId);

  @override
  String toString() {
    return 'RunTransactionAction($control, $executorId)';
  }
}

/// Sent from the client to the server. The server should open the underlying
/// database connection, using the [schemaVersion].
class _EnsureOpen {
  final int schemaVersion;
  final int? executorId;

  _EnsureOpen(this.schemaVersion, this.executorId);

  @override
  String toString() {
    return 'EnsureOpen($schemaVersion, $executorId)';
  }
}

/// Sent from the server to the client when it should run the before open
/// callback.
class _RunBeforeOpen {
  final OpeningDetails details;
  final int createdExecutor;

  _RunBeforeOpen(this.details, this.createdExecutor);

  @override
  String toString() {
    return 'RunBeforeOpen($details, $createdExecutor)';
  }
}

/// Sent to notify that a previous query has updated some tables. When a server
/// receives this message, it replies with `null` but forwards a new request
/// with this payload to all connected clients.
class _NotifyTablesUpdated {
  final List<TableUpdate> updates;

  _NotifyTablesUpdated(this.updates);
}
