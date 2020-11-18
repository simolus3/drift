//@dart=2.9
import 'dart:async';

import 'package:moor/moor.dart' hide isNull;
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

final _dataOfTodoEntry = {
  'id': 10,
  'title': 'A todo title',
  'content': 'Content',
  'category': 3
};

final _todoEntry = TodoEntry(
  id: 10,
  title: 'A todo title',
  content: 'Content',
  category: 3,
);

void main() {
  TodoDb db;
  MockExecutor executor;

  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  group('SELECT statements are generated', () {
    test('for simple statements', () async {
      await db.select(db.users, distinct: true).get();
      verify(executor.runSelect(
          'SELECT DISTINCT * FROM users;', argThat(isEmpty)));
    });

    test('with limit statements', () async {
      await (db.select(db.users)..limit(10, offset: 0)).get();
      verify(executor.runSelect(
          'SELECT * FROM users LIMIT 10 OFFSET 0;', argThat(isEmpty)));
    });

    test('with simple limits', () async {
      await (db.select(db.users)..limit(10)).get();

      verify(executor.runSelect(
          'SELECT * FROM users LIMIT 10;', argThat(isEmpty)));
    });

    test('with like expressions', () async {
      await (db.select(db.users)..where((u) => u.name.like('Dash%'))).get();
      verify(executor
          .runSelect('SELECT * FROM users WHERE name LIKE ?;', ['Dash%']));
    });

    test('with order-by clauses', () async {
      await (db.select(db.users)
            ..orderBy([
              (u) => OrderingTerm.desc(u.isAwesome),
              (u) => OrderingTerm.asc(u.id)
            ]))
          .get();

      verify(executor.runSelect(
          'SELECT * FROM users ORDER BY '
          'is_awesome DESC, id ASC;',
          argThat(isEmpty)));
    });

    test('with complex predicates', () async {
      await (db.select(db.users)
            ..where((u) =>
                u.name.equals('Dash').not() & u.id.isBiggerThanValue(12)))
          .get();

      verify(executor.runSelect(
          'SELECT * FROM users WHERE NOT (name = ?) AND id > ?;',
          ['Dash', 12]));
    });

    test('with expressions from boolean columns', () async {
      await (db.select(db.users)..where((u) => u.isAwesome)).get();

      verify(executor.runSelect(
          'SELECT * FROM users WHERE is_awesome;', argThat(isEmpty)));
    });

    test('with aliased tables', () async {
      final users = db.alias(db.users, 'u');
      await (db.select(users)
            ..where((u) => u.id.isSmallerThan(const Constant(5))))
          .get();

      verify(executor.runSelect('SELECT * FROM users u WHERE id < 5;', []));
    });
  });

  group('SELECT results are parsed', () {
    test('when all fields are non-null', () {
      when(executor.runSelect('SELECT * FROM todos;', any))
          .thenAnswer((_) => Future.value([_dataOfTodoEntry]));

      expect(db.select(db.todosTable).get(), completion([_todoEntry]));
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

  group('queries for a single row', () {
    test('get once', () {
      when(executor.runSelect('SELECT * FROM todos;', any))
          .thenAnswer((_) => Future.value([_dataOfTodoEntry]));

      expect(db.select(db.todosTable).getSingle(), completion(_todoEntry));
    });

    test('get multiple times', () {
      final resultRows = <List<Map<String, dynamic>>>[
        [_dataOfTodoEntry],
        [],
        [_dataOfTodoEntry, _dataOfTodoEntry],
      ];
      var _currentRow = 0;

      when(executor.runSelect('SELECT * FROM todos;', any)).thenAnswer((_) {
        return Future.value(resultRows[_currentRow++]);
      });

      expectLater(db.select(db.todosTable).watchSingle(),
          emitsInOrder([_todoEntry, isNull, emitsError(anything)]));

      db
        ..markTablesUpdated({db.todosTable})
        ..markTablesUpdated({db.todosTable});
    });
  });

  test('applies implicit type converter', () async {
    when(executor.runSelect(any, any)).thenAnswer((_) {
      return Future.value([
        {
          'id': 1,
          'desc': 'description',
          'priority': 2,
        }
      ]);
    });

    final category = await db.select(db.categories).getSingle();

    expect(
      category,
      Category(
        id: 1,
        description: 'description',
        priority: CategoryPriority.high,
      ),
    );
  });
}
