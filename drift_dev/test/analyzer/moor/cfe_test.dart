//@dart=2.9
import 'package:build/build.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/runner/file_graph.dart';
import 'package:drift_dev/src/analyzer/runner/results.dart';
import 'package:drift_dev/src/analyzer/runner/task.dart';
import 'package:drift_dev/src/analyzer/session.dart';
import 'package:test/test.dart';

import '../../utils/test_backend.dart';

void main() {
  TestBackend backend;
  MoorSession session;
  Task task;

  setUpAll(() {
    backend = TestBackend(
      {
        AssetId.parse('foo|lib/test.moor'): r'''
CREATE TABLE foo (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  bar VARCHAR NOT NULL
);

test:
WITH RECURSIVE
  cnt(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM cnt
    LIMIT 1000000
  )
  SELECT x FROM cnt;
  
test2:
WITH alias("first", second) AS (SELECT * FROM foo) SELECT * FROM alias;
         ''',
      },
    );
    session = MoorSession(backend);
  });

  setUp(() async {
    final backendTask = backend.startTask(Uri.parse('package:foo/test.moor'));
    task = session.startTask(backendTask);
    await task.runTask();
  });

  tearDownAll(() {
    backend.finish();
  });

  test('recognizes CFE clause', () {
    final file = session.registerFile(Uri.parse('package:foo/test.moor'));

    expect(file.state, FileState.analyzed);
    expect(file.errors.errors, isEmpty);

    final result = file.currentResult as ParsedMoorFile;
    final query = result.resolvedQueries.firstWhere((q) => q.name == 'test')
        as SqlSelectQuery;

    expect(query.variables, isEmpty);
    expect(query.declaredInMoorFile, isTrue);
    expect(query.readsFrom, isEmpty);

    final resultSet = query.resultSet;
    expect(resultSet.singleColumn, isTrue);
    expect(resultSet.needsOwnClass, isFalse);
    expect(resultSet.columns.map(resultSet.dartNameFor), ['x']);
    expect(resultSet.columns.map((c) => c.type), [ColumnType.integer]);
  });

  test('finds the underlying table when aliased through CFE', () {
    final file = session.registerFile(Uri.parse('package:foo/test.moor'));
    final result = file.currentResult as ParsedMoorFile;
    final query = result.resolvedQueries.firstWhere((q) => q.name == 'test2')
        as SqlSelectQuery;

    final resultSet = query.resultSet;

    expect(resultSet.matchingTable, isNotNull);
    expect(resultSet.matchingTable.table.displayName, 'foo');
    expect(resultSet.needsOwnClass, isFalse);
  });
}
