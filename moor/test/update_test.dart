import 'dart:async';

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

  group('generates update statements', () {
    test('for entire table', () async {
      await db
          .update(db.todosTable)
          .write(TodoEntry(title: 'Updated title', category: 3));

      verify(executor.runUpdate(
          'UPDATE todos SET title = ?, category = ?;', ['Updated title', 3]));
    });

    test('with a WHERE clause', () async {
      await (db.update(db.todosTable)
            ..where((t) => t.id.isSmallerThanValue(50)))
          .write(TodoEntry(title: 'Changed title'));

      verify(executor.runUpdate(
          'UPDATE todos SET title = ? WHERE id < ?;', ['Changed title', 50]));
    });
  });

  test('generates replace statements', () async {
    await db.update(db.todosTable).replace(TodoEntry(
          id: 3,
          title: 'Title',
          content: 'Updated content',
          // category and targetDate are null
        ));

    verify(executor.runUpdate(
        'UPDATE todos SET title = ?, content = ?, '
        'target_date = NULL, category = NULL WHERE id = ?;',
        ['Title', 'Updated content', 3]));
  });

  test('does not update with invalid data', () {
    // The length of a title must be between 4 and 16 chars

    expect(() async {
      await db.into(db.todosTable).insert(TodoEntry(title: 'lol'));
    }, throwsA(const TypeMatcher<InvalidDataException>()));
  });

  group('Table updates for update statements', () {
    test('are issued when data was changed', () async {
      when(executor.runUpdate(any, any)).thenAnswer((_) => Future.value(3));

      await db.update(db.todosTable).write(TodoEntry(
            content: 'Updated content',
          ));

      verify(streamQueries.handleTableUpdates('todos'));
    });

    test('are not issued when no data was changed', () async {
      when(executor.runDelete(any, any)).thenAnswer((_) => Future.value(0));

      await db.update(db.todosTable).write(TodoEntry());

      verifyNever(streamQueries.handleTableUpdates(any));
    });
  });

  group('custom updates', () {
    test('execute the correct sql', () async {
      await db.customUpdate('DELETE FROM users');

      verify(executor.runUpdate('DELETE FROM users', []));
    });

    test('map the variables correctly', () async {
      await db.customUpdate(
          'DELETE FROM users WHERE name = ? AND birthdate < ?',
          variables: [
            Variable.withString('Name'),
            Variable.withDateTime(
                DateTime.fromMillisecondsSinceEpoch(1551297563000))
          ]);

      verify(executor.runUpdate(
          'DELETE FROM users WHERE name = ? AND birthdate < ?',
          ['Name', 1551297563]));
    });

    test('returns information from executor', () async {
      when(executor.runUpdate(any, any)).thenAnswer((_) => Future.value(10));

      expect(await db.customUpdate(''), 10);
    });

    test('informs about updated tables', () async {
      await db.customUpdate('', updates: {db.users, db.todosTable});

      verify(streamQueries.handleTableUpdates('users'));
      verify(streamQueries.handleTableUpdates('todos'));
    });
  });
}
