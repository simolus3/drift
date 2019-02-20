import 'dart:async';

import 'package:sally/sally.dart';
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
          'UPDATE todos SET title = ? category = ?;', ['Updated title', 3]));
    });

    test('with a WHERE clause', () async {
      await (db.update(db.todosTable)
            ..where((t) => t.id.isSmallerThanValue(50)))
          .write(TodoEntry(title: 'Changed title'));

      verify(executor.runUpdate(
          'UPDATE todos SET title = ? WHERE id < ?;', ['Changed title', 50]));
    });
  });

  test('does not update with invalid data', () {
    // The length of a title must be between 4 and 16 chars

    expect(() async {
      await db.into(db.todosTable).insert(TodoEntry(title: 'lol'));
    }, throwsA(const TypeMatcher<InvalidDataException>()));
  });

  group('Table updates for delete statements', () {
    test('are issued when data was changed', () async {
      when(executor.runUpdate(any, any)).thenAnswer((_) => Future.value(3));

      await db.update(db.todosTable).write(TodoEntry());

      verify(streamQueries.handleTableUpdates('todos'));
    });

    test('are not issued when no data was changed', () async {
      when(executor.runDelete(any, any)).thenAnswer((_) => Future.value(0));

      await db.update(db.todosTable).write(TodoEntry());

      verifyNever(streamQueries.handleTableUpdates(any));
    });
  });
}
