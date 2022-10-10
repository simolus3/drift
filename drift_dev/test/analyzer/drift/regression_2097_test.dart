import 'package:drift_dev/src/analyzer/options.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  // https://github.com/simolus3/drift/issues/2097#issuecomment-1273008383
  test('supports fts5 tables with external content', () async {
    final state = TestState.withContent(
      {
        'foo|lib/a.drift': r'''
CREATE TABLE IF NOT EXISTS nodes (
    body TEXT,
    id   TEXT GENERATED ALWAYS AS (json_extract(body, '$.id')) VIRTUAL NOT NULL UNIQUE
);

insertNode: INSERT INTO nodes VALUES(json(?));
      ''',
      },
      options: const DriftOptions.defaults(
          sqliteAnalysisOptions:
              SqliteAnalysisOptions(version: SqliteVersion.v3_39)),
    );

    final result = await state.analyze('package:foo/a.drift');

    expect(result.errors.errors, isEmpty);

    final table = result.currentResult!.declaredTables.single;
    expect(table.sqlName, 'nodes');
    expect(table.columns, hasLength(2));
    expect(table.isColumnRequiredForInsert(table.columns[0]), isFalse);
    expect(table.isColumnRequiredForInsert(table.columns[1]), isFalse);
  });
}
