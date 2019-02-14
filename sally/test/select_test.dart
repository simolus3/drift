import 'package:sally/sally.dart';
import 'package:test_api/test_api.dart';

import 'lib/tables/todos.dart';
import 'lib/utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;

  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  group('SELECT statements are generated', () {
    test('for simple statements', () {
      db.select(db.users).get();
      verify(executor.runSelect('SELECT * FROM users;', argThat(isEmpty)));
    });

    test('with limit statements', () {
      (db.select(db.users)..limit(10)).get();
      verify(executor.runSelect(
          'SELECT * FROM users LIMIT 10;', argThat(isEmpty)));
    });

    test('with like expressions', () {
      (db.select(db.users)..where((u) => u.name.like('Dash%'))).get();
      verify(executor
          .runSelect('SELECT * FROM users WHERE name LIKE ?;', ['Dash%']));
    });

    test('with complex predicates', () {
      (db.select(db.users)
            ..where((u) =>
                and(not(u.name.equals('Dash')), (u.id.isBiggerThan(12)))))
          .get();

      verify(executor.runSelect(
          'SELECT * FROM users WHERE (NOT name = ?) AND (id > ?);',
          ['Dash', 12]));
    });

    test('with expressions from boolean columns', () {
      (db.select(db.users)..where((u) => u.isAwesome)).get();

      verify(executor.runSelect(
          'SELECT * FROM users WHERE (is_awesome = 1);', argThat(isEmpty)));
    });
  });

  group('SELECT results are parsed', () {
    test('when all fields are non-null', () {
      final data = [
        {'id': 10, 'title': 'A todo title', 'content': 'Content', 'category': 3}
      ];
      final resolved = TodoEntry(
        id: 10,
        title: 'A todo title',
        content: 'Content',
        category: 3,
      );

      when(executor.runSelect('SELECT * FROM todos;', any))
          .thenAnswer((_) => Future.value(data));

      expect(db.select(db.todosTable).get(), completion([resolved]));
    });

    test('when some fields are null', () {
      final data = [
        {
          'id': 10,
          'title': null,
          'content': 'Content',
          'category': null,
        }
      ];
      final resolved = TodoEntry(
        id: 10,
        title: null,
        content: 'Content',
        category: null,
      );

      when(executor.runSelect('SELECT * FROM todos;', any))
          .thenAnswer((_) => Future.value(data));

      expect(db.select(db.todosTable).get(), completion([resolved]));
    });
  });
}
