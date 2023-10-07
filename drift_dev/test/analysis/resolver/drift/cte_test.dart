import 'package:drift/drift.dart' show DriftSqlType;
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('parse nested CTE', () async {
    final backend = TestBackend.inTest({
      'a|lib/test.drift': '''
test:
SELECT
    *
    FROM
      (
	      WITH cte AS (
	          SELECT 1 AS val
	      )
	      SELECT * from cte
      );
'''
    });

    final file = await backend.analyze('package:a/test.drift');
    backend.expectNoErrors();

    final query =
        file.fileAnalysis!.resolvedQueries.values.single as SqlSelectQuery;

    expect(query.variables, isEmpty);
    expect(query.readsFrom, isEmpty);

    final resultSet = query.resultSet;
    expect(resultSet.singleColumn, isTrue);
    expect(resultSet.needsOwnClass, isFalse);
    expect(resultSet.scalarColumns.map((c) => c.sqlType.builtin),
        [DriftSqlType.int]);
  });

  test('recognizes CTE clause', () async {
    final backend = TestBackend.inTest({
      'a|lib/test.drift': '''
test:
WITH RECURSIVE
  cnt(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM cnt
    LIMIT 1000000
  )
  SELECT x FROM cnt;
'''
    });

    final file = await backend.analyze('package:a/test.drift');
    backend.expectNoErrors();

    final query =
        file.fileAnalysis!.resolvedQueries.values.single as SqlSelectQuery;

    expect(query.variables, isEmpty);
    expect(query.readsFrom, isEmpty);

    final resultSet = query.resultSet;
    expect(resultSet.singleColumn, isTrue);
    expect(resultSet.needsOwnClass, isFalse);
    expect(resultSet.columns.map(resultSet.dartNameFor), ['x']);
    expect(resultSet.scalarColumns.map((c) => c.sqlType.builtin),
        [DriftSqlType.int]);
  });

  test('finds the underlying table when aliased through CTE', () async {
    final backend = TestBackend.inTest({
      'a|lib/test.drift': '''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  bar VARCHAR NOT NULL
);

test2:
WITH alias("first", second) AS (SELECT * FROM foo) SELECT * FROM alias;
'''
    });

    final file = await backend.analyze('package:a/test.drift');
    backend.expectNoErrors();

    final query =
        file.fileAnalysis!.resolvedQueries.values.single as SqlSelectQuery;
    final resultSet = query.resultSet;

    expect(resultSet.matchingTable, isNotNull);
    expect(resultSet.matchingTable!.table.schemaName, 'foo');
    expect(resultSet.needsOwnClass, isFalse);
  });
}
