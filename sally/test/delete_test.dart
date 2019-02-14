import 'package:sally/sally.dart';
import 'package:test_api/test_api.dart';

import 'tables/todos.dart';
import 'utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;
  MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();
    db = TodoDb(executor)..streamQueries = streamQueries;
  });

  group('Generates DELETE statements', () {
    test('without any constraints', () async {
      await db.delete(db.users).go();

      verify(executor.runDelete('DELETE FROM users;', argThat(isEmpty)));
    });

    test('for complex components', () async {
      await (db.delete(db.users)
        ..where((u) => or(not(u.isAwesome), u.id.isSmallerThan(100)))
        ..limit(10, offset: 100))
          .go();

      verify(executor.runDelete(
          'DELETE FROM users WHERE (NOT (is_awesome = 1)) OR (id < ?) LIMIT 10, 100;',
          [100]));
    });
  });

  group('Table updates for delete statements', () {
    test('are issued when data was changed', () async {
      when(executor.runDelete(any, any)).thenAnswer((_) => Future.value(3));

      await db.delete(db.users).go();

      verify(streamQueries.handleTableUpdates('users'));
    });

    test('are not issued when no data was changed', () async {
      when(executor.runDelete(any, any)).thenAnswer((_) => Future.value(0));

      await db.delete(db.users).go();

      verifyNever(streamQueries.handleTableUpdates(any));
    });
  });
}