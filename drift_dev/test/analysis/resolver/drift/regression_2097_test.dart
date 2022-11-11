import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:drift_dev/src/analysis/options.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  // https://github.com/simolus3/drift/issues/2097#issuecomment-1273008383
  test('virtual columns are not required for inserts', () async {
    final state = TestBackend.inTest(
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

    final table = result.analysis[result.id('nodes')]!.result as DriftTable;

    expect(table.schemaName, 'nodes');
    expect(table.columns, hasLength(2));
    expect(table.isColumnRequiredForInsert(table.columns[0]), isFalse);
    expect(table.isColumnRequiredForInsert(table.columns[1]), isFalse);

    state.expectNoErrors();
  });
}
