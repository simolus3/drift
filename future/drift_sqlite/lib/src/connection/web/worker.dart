import 'dart:js_interop';

import 'package:sqlite3/wasm.dart';

import 'package:sqlite3_web/sqlite3_web.dart';
import 'package:sqlite3_web/protocol_utils.dart' as utils;

import 'protocol.dart';

/// A [DatabaseController] opening [DriftWorkerDatabase]s.
final class DriftDatabaseController extends DatabaseController {
  @override
  Future<JSAny?> handleCustomRequest(
    ClientConnection connection,
    CustomClientRequest request,
  ) {
    throw UnsupportedError('handleCustomRequest on controller');
  }

  @override
  Future<WorkerDatabase> openDatabase(
    WasmSqlite3 sqlite3,
    String path,
    String vfs,
    JSAny? additionalData,
  ) async {
    return DriftWorkerDatabase(sqlite3.open(path, vfs: vfs));
  }
}

/// A [WorkerDatabase] handling custom requests sent by the drift client to
/// execute statements.
final class DriftWorkerDatabase extends WorkerDatabase {
  @override
  final CommonDatabase database;

  /// Wraps a synchronous database instance for the worker.
  DriftWorkerDatabase(this.database);

  @override
  Future<JSAny?> handleCustomRequest(
    ClientConnection connection,
    CustomClientDatabaseRequest request,
  ) {
    final data = request.request as BaseRequest;

    return request.useLock(() {
      if (data.requireInTransaction && database.autocommit) {
        throw SqliteException(
          extendedResultCode: 0,
          message: 'Not in a transaction',
        );
      }

      switch (data.type) {
        case BaseRequest.typeExecute:
          return _handleExecuteRequest(data as ExecuteRequest);
        case BaseRequest.typeExecuteBatch:
          return _handleExecuteBatchRequest(data as ExecuteBatchRequest);
        default:
          throw UnsupportedError('Unknown request type ${data.type}');
      }
    });
  }

  SerializedQueryResult _handleExecuteRequest(ExecuteRequest data) {
    JSObject? resultSet;

    if (!data.needsResultSet && data.parameters.length == 0) {
      database.execute(data.sql);
    } else {
      final stmt = database.prepare(data.sql, checkNoTail: true);
      try {
        final params = data.decodedParameters;

        if (data.needsResultSet) {
          resultSet = utils.runStatementAndEncodeResults(stmt, params);
        } else {
          stmt.executeWith(params.asParameters);
        }
      } finally {
        stmt.close();
      }
    }

    return _serializeResult(resultSet);
  }

  JSArray<SerializedQueryResult> _handleExecuteBatchRequest(
    ExecuteBatchRequest request,
  ) {
    final statements = <CommonPreparedStatement>[];

    try {
      for (final sql in request.sql.toDart) {
        statements.add(database.prepare(sql.toDart, checkNoTail: true));
      }

      final results = JSArray<SerializedQueryResult>.withLength(
        request.entries.length,
      );
      for (var i = 0; i < request.entries.length; i++) {
        final entry = request.entries[i];
        final stmt = statements[entry.sqlIndex];
        final params = entry.decodedParameters;
        JSObject? resultSet;

        if (entry.needsResultSet) {
          resultSet = utils.runStatementAndEncodeResults(stmt, params);
        } else {
          stmt.executeWith(params.asParameters);
        }

        results[i] = _serializeResult(resultSet);
      }

      return results;
    } finally {
      for (final stmt in statements) {
        stmt.close();
      }
    }
  }

  SerializedQueryResult _serializeResult(JSObject? resultSet) {
    return SerializedQueryResult(
      affectedRows: database.updatedRows.toJS,
      lastInsertRowId: database.lastInsertRowId.toJS,
      serializedResultSet: resultSet,
    );
  }
}
