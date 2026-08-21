import 'dart:js_interop';

import 'package:drift3_preview/drift.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3_web/protocol_utils.dart' as utils;

@JS()
@anonymous
@internal
extension type BaseRequest._(JSObject _) implements JSObject {
  @JS('e')
  external bool get requireInTransaction;

  @JS('t')
  external String get type;

  static const String typeExecute = 'e';
  static const String typeExecuteBatch = 'b';
}

/// A serialized [StatementInfo].
@JS()
@anonymous
@internal
extension type ExecuteRequest._(JSObject _) implements BaseRequest {
  @JS('a')
  external String get sql;
  @JS('b')
  external JSArray get parameters;
  @JS('c')
  external JSArrayBuffer get parameterTypes;
  @JS('d')
  external bool get needsResultSet;

  external factory ExecuteRequest({
    @JS('a') required String sql,
    @JS('b') required JSArray parameters,
    @JS('c') required JSArrayBuffer parameterTypes,
    @JS('d') required bool needsResultSet,
    @JS('e') required bool requireInTransaction,
    @JS('t') required String type,
  });

  utils.DecodedTypedValues get decodedParameters =>
      utils.deserializeParameters(parameters, parameterTypes);
}

/// A serialized [StatementBatch].
@JS()
@anonymous
@internal
extension type ExecuteBatchRequest._(JSObject _) implements BaseRequest {
  @JS('a')
  external JSArray<JSString> get sql;
  @JS('b')
  external JSArray<ExecuteBatchEntry> get entries;
  @JS('e')
  external bool requireInTransaction;

  external factory ExecuteBatchRequest({
    @JS('a') required JSArray<JSString> sql,
    @JS('b') required JSArray<ExecuteBatchEntry> entries,
    @JS('e') required bool requireInTransaction,
    @JS('t') required String type,
  });
}

/// A serialized [StatementInBatch].
@JS()
@anonymous
@internal
extension type ExecuteBatchEntry._(JSObject _) implements JSObject {
  @JS('a')
  external int sqlIndex;
  @JS('b')
  external JSArray get parameters;
  @JS('c')
  external JSArrayBuffer get parameterTypes;
  @JS('d')
  external bool get needsResultSet;

  external factory ExecuteBatchEntry({
    @JS('a') required int sqlIndex,
    @JS('b') required JSArray parameters,
    @JS('c') required JSArrayBuffer parameterTypes,
    @JS('d') required bool needsResultSet,
  });

  utils.DecodedTypedValues get decodedParameters =>
      utils.deserializeParameters(parameters, parameterTypes);
}

/// A serialized [QueryResult].
@JS()
@anonymous
@internal
extension type SerializedQueryResult._(JSObject _) implements JSObject {
  @JS('a')
  external JSNumber? get affectedRows;
  @JS('b')
  external JSNumber? get lastInsertRowId;
  @JS('c')
  external JSObject? get serializedResultSet;

  external factory SerializedQueryResult({
    @JS('a') required JSNumber? affectedRows,
    @JS('b') required JSNumber? lastInsertRowId,
    @JS('c') required JSObject? serializedResultSet,
  });

  QueryResult asQueryResult() {
    RawResultSet? resultSet;
    if (serializedResultSet case final serialized?) {
      final rawResultSet = utils.deserializeResultSet(serialized);
      resultSet = RawResultSet.fromRows(
        columnNames: rawResultSet.columnNames,
        rows: rawResultSet.rows,
      );
    }

    return QueryResult(
      resultSet: resultSet,
      affectedRows: affectedRows?.toDartInt,
      lastInsertRowId: lastInsertRowId?.toDartInt,
    );
  }
}
