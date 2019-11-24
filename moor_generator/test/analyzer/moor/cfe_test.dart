import 'package:build/build.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/analyzer/runner/task.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/sql_query.dart';
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
test:
WITH RECURSIVE
  cnt(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM cnt
    LIMIT 1000000
  )
  SELECT x FROM cnt;
         ''',
      },
    );
    session = backend.session;
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
    final query = result.resolvedQueries.single as SqlSelectQuery;

    expect(query.name, 'test');
    expect(query.variables, isEmpty);
    expect(query.declaredInMoorFile, isTrue);
    expect(query.readsFrom, isEmpty);

    final resultSet = query.resultSet;
    expect(resultSet.singleColumn, isTrue);
    expect(resultSet.needsOwnClass, isFalse);
    expect(resultSet.columns.map(resultSet.dartNameFor), ['x']);
    expect(resultSet.columns.map((c) => c.type), [ColumnType.integer]);
  });
}
