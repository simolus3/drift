import 'package:moor/moor.dart';
import 'package:test_api/test_api.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;
  MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();
    db = TodoDb(executor)..streamQueries = streamQueries;
  });

  group('compiled custom queries', () {
    // defined query: SELECT * FROM todos WHERE title = ?2 OR id IN ? OR title = ?1
    test('work with arrays', () async {
      await db.withIn('one', 'two', [1, 2, 3]);

      verify(
        executor.runSelect(
          'SELECT * FROM todos WHERE title = ?2 OR id IN (?3, ?4, ?5) OR title = ?1',
          ['one', 'two', 1, 2, 3],
        ),
      );
    });
  });

  test('custom update informs stream queries', () async {
    await db.customUpdate('UPDATE tbl SET a = ?',
        variables: [Variable.withString('hi')], updates: {db.users});

    verify(executor.runUpdate('UPDATE tbl SET a = ?', ['hi']));
    verify(streamQueries.handleTableUpdates({db.users}));
  });

  test('custom insert', () async {
    when(executor.runInsert(any, any)).thenAnswer((_) => Future.value(32));

    final id =
        await db.customInsert('fake insert', variables: [Variable.withInt(3)]);
    expect(id, 32);

    // shouldn't call stream queries - we didn't set the updates parameter
    verifyNever(streamQueries.handleTableUpdates(any));
  });
}
