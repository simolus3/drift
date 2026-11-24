/// Conversions between drift classes and their protobuf representation, shared
/// by the client and the server.
library;

import 'dart:typed_data';

import 'package:drift3_preview/drift.dart';
import 'package:fixnum/fixnum.dart';

import 'generated/drift.pb.dart' as gen;

gen.StatementInfo statementToProto(StatementInfo info) {
  return gen.StatementInfo(
    sql: info.sql,
    needsResultSet: info.needsResultSet,
    variables: info.variables.map(valueToProto),
    watchedTables: info.watchedTables,
    expectedWrites: info.expectedWrites.map(tableUpdateToProto),
    isReadOnly: info.isReadOnly,
  );
}

StatementInfo statementFromProto(gen.StatementInfo info) {
  return StatementInfo(
    info.sql,
    needsResultSet: info.needsResultSet,
    variables: info.variables.map(valueFromProto).toList(),
    watchedTables: info.watchedTables.toList(),
    expectedWrites: info.expectedWrites.map(tableUpdateFromProto).toSet(),
    isReadOnly: info.isReadOnly,
  );
}

gen.StatementBatch batchToProto(StatementBatch batch) {
  return gen.StatementBatch(
    sql: batch.sql,
    statements: [
      for (final statement in batch.statements)
        gen.StatementInBatch(
          sqlIndex: statement.sqlIndex,
          info: statementToProto(statement.info),
        ),
    ],
  );
}

StatementBatch batchFromProto(gen.StatementBatch batch) {
  return StatementBatch(
    sql: batch.sql.toList(),
    statements: [
      for (final statement in batch.statements)
        StatementInBatch(
          statement.sqlIndex,
          statementFromProto(statement.info),
        ),
    ],
  );
}

gen.SqlValue valueToProto(Object? value) {
  return switch (value) {
    null => gen.SqlValue(),
    int() => gen.SqlValue(intValue: Int64(value)),
    BigInt() => gen.SqlValue(intValue: Int64.parseInt(value.toString())),
    bool() => gen.SqlValue(intValue: value ? Int64.ONE : Int64.ZERO),
    double() => gen.SqlValue(doubleValue: value),
    String() => gen.SqlValue(textValue: value),
    List<int>() => gen.SqlValue(blobValue: value),
    _ => throw ArgumentError.value(value, 'value', 'Unsupported SQL value'),
  };
}

Object? valueFromProto(gen.SqlValue value) {
  return switch (value.whichValue()) {
    gen.SqlValue_Value.notSet => null,
    gen.SqlValue_Value.intValue => value.intValue.toInt(),
    gen.SqlValue_Value.doubleValue => value.doubleValue,
    gen.SqlValue_Value.textValue => value.textValue,
    gen.SqlValue_Value.blobValue => Uint8List.fromList(value.blobValue),
  };
}

gen.QueryResult resultToProto(QueryResult result) {
  final resultSet = result.resultSet;

  return gen.QueryResult(
    affectedRows: switch (result.affectedRows) {
      final rows? => Int64(rows),
      null => null,
    },
    lastInsertRowId: switch (result.lastInsertRowId) {
      final id? => Int64(id),
      null => null,
    },
    resultSet: resultSet == null
        ? null
        : gen.ResultSet(
            columnNames: resultSet.columnNames,
            rows: [
              for (final row in resultSet)
                gen.Row(values: row.map(valueToProto)),
            ],
          ),
  );
}

QueryResult resultFromProto(gen.QueryResult result) {
  return QueryResult(
    affectedRows: result.hasAffectedRows() ? result.affectedRows.toInt() : null,
    lastInsertRowId: result.hasLastInsertRowId()
        ? result.lastInsertRowId.toInt()
        : null,
    resultSet: result.hasResultSet()
        ? RawResultSet.fromRows(
            columnNames: result.resultSet.columnNames.toList(),
            rows: [
              for (final row in result.resultSet.rows)
                row.values.map(valueFromProto).toList(),
            ],
          )
        : null,
  );
}

gen.TableUpdates tableUpdatesToProto(Iterable<TableUpdate> updates) {
  return gen.TableUpdates(updates: updates.map(tableUpdateToProto));
}

Set<TableUpdate> tableUpdatesFromProto(gen.TableUpdates updates) {
  return updates.updates.map(tableUpdateFromProto).toSet();
}

gen.TableUpdate tableUpdateToProto(TableUpdate update) {
  return gen.TableUpdate(
    table: update.table,
    kind: switch (update.kind) {
      null => gen.UpdateKind.UPDATE_KIND_UNKNOWN,
      UpdateKind.insert => gen.UpdateKind.UPDATE_KIND_INSERT,
      UpdateKind.update => gen.UpdateKind.UPDATE_KIND_UPDATE,
      UpdateKind.delete => gen.UpdateKind.UPDATE_KIND_DELETE,
    },
  );
}

TableUpdate tableUpdateFromProto(gen.TableUpdate update) {
  return TableUpdate(
    update.table,
    kind: switch (update.kind) {
      gen.UpdateKind.UPDATE_KIND_INSERT => UpdateKind.insert,
      gen.UpdateKind.UPDATE_KIND_UPDATE => UpdateKind.update,
      gen.UpdateKind.UPDATE_KIND_DELETE => UpdateKind.delete,
      _ => null,
    },
  );
}
