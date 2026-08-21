import 'package:drift3_preview/drift.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3/common.dart' as sqlite;

/// A [PersistentSchemaVersion] implementation based on `PRAGMA user_version`.
@internal
final class PragmaPersistedSchemaVersion implements PersistentSchemaVersion {
  final DriftSession _inner;

  PragmaPersistedSchemaVersion(this._inner);

  @override
  Future<int> get schemaVersion async {
    final result = await _inner.execute(
      StatementInfo('PRAGMA user_version', needsResultSet: true),
    );

    return result.resultSet![0][0] as int;
  }

  @override
  Future<void> writeSchemaVersion(int version) async {
    await _inner.execute(StatementInfo('PRAGMA user_version = $version;'));
  }
}

@internal
QueryResult executeWithStatement(
  sqlite.CommonDatabase database,
  sqlite.CommonPreparedStatement stmt,
  StatementInfo info,
) {
  final variables = info.variables.map((e) => e.rawValue).toList();
  RawResultSet? resultSet;

  if (info.needsResultSet) {
    resultSet = SqliteResultSet(resultSet: stmt.select(variables));
  } else {
    stmt.execute(variables);
  }

  return QueryResult(
    affectedRows: database.updatedRows,
    resultSet: resultSet,
    lastInsertRowId: database.lastInsertRowId,
  );
}

@internal
final class SqliteResultSet extends RawResultSet {
  final sqlite.ResultSet resultSet;

  SqliteResultSet({required this.resultSet})
    : super(columnNames: resultSet.columnNames);

  @override
  RawRow operator [](int index) {
    return resultSet[index].values;
  }

  @override
  int get length => resultSet.length;
}
