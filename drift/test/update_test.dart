import 'dart:async';

import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  late TodoDb db;
  late MockExecutor executor;
  late MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();

    final connection = createConnection(executor, streamQueries);
    db = TodoDb.connect(connection);
  });

  group('generates update statements', () {
    test('for entire table', () async {
      await db.update(db.todosTable).write(const TodosTableCompanion(
            title: Value('Updated title'),
            category: Value(3),
          ));

      verify(executor.runUpdate(
          'UPDATE todos SET title = ?, category = ?;', ['Updated title', 3]));
    });

    test('with a WHERE clause', () async {
      await (db.update(db.todosTable)
            ..where((t) => t.id.isSmallerThanValue(50)))
          .write(const TodosTableCompanion(title: Value('Changed title')));

      verify(executor.runUpdate(
          'UPDATE todos SET title = ? WHERE id < ?;', ['Changed title', 50]));
    });

    test('with escaped column names', () async {
      await db
          .update(db.pureDefaults)
          .write(const PureDefaultsCompanion(txt: Value('foo')));

      verify(executor
          .runUpdate('UPDATE pure_defaults SET "insert" = ?;', ['foo']));
    });
  });

  group('generates replace statements', () {
    test('regular', () async {
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

    test('applies default values', () async {
      await db.update(db.users).replace(
            UsersCompanion(
              id: const Value(3),
              name: const Value('Hummingbird'),
              profilePicture: Value(Uint8List(0)),
            ),
          );

      verify(executor.runUpdate(
          'UPDATE users SET name = ?, profile_picture = ?, is_awesome = 1, '
          'creation_time = strftime(\'%s\', CURRENT_TIMESTAMP) WHERE id = ?;',
          ['Hummingbird', Uint8List(0), 3]));
    });
  });

  test('does not update with invalid data', () {
    // The length of a title must be between 4 and 16 chars

    expect(() async {
      await db
          .update(db.todosTable)
          .write(const TodosTableCompanion(title: Value('lol')));
    }, throwsA(const TypeMatcher<InvalidDataException>()));
  });

  group('Table updates for update statements', () {
    test('are issued when data was changed', () async {
      when(executor.runUpdate(any, any)).thenAnswer((_) => Future.value(3));

      await db.update(db.todosTable).write(const TodosTableCompanion(
            content: Value('Updated content'),
          ));

      verify(streamQueries.handleTableUpdates(
          {TableUpdate.onTable(db.todosTable, kind: UpdateKind.update)}));
    });

    test('are not issued when no data was changed', () async {
      when(executor.runDelete(any, any)).thenAnswer((_) => Future.value(0));

      await db.update(db.todosTable).write(const TodosTableCompanion());

      verifyNever(streamQueries.handleTableUpdates(any));
    });
  });

  test('can update with custom companions', () async {
    await db.update(db.todosTable).replace(TodosTableCompanion.custom(
          id: const Variable(4),
          content: db.todosTable.content.dartCast(),
          targetDate: db.todosTable.targetDate + const Duration(days: 1),
        ));

    verify(executor.runUpdate(
      'UPDATE todos SET content = content, target_date = target_date + ? '
      'WHERE id = ?;',
      argThat(equals([86400, 4])),
    ));
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

      verify(streamQueries.handleTableUpdates(
          {const TableUpdate('users'), const TableUpdate('todos')}));
    });
  });

  group('update with from()', () {
    test('update()', () async {
      await db
          .from(db.users)
          .update()
          .write(const UsersCompanion(id: Value(3)));

      verify(executor.runUpdate('UPDATE users SET id = ?;', [3]));
    });

    test('replace', () async {
      await db.from(db.categories).replace(const CategoriesCompanion(
          id: Value(3), description: Value('new name')));

      verify(executor.runUpdate(
          'UPDATE categories SET "desc" = ?, priority = 0 WHERE id = ?;',
          ['new name', 3]));
    });
  });

  group('update on table instances', () {
    test('update()', () async {
      await db.users.update().write(const UsersCompanion(id: Value(3)));

      verify(executor.runUpdate('UPDATE users SET id = ?;', [3]));
    });

    test('replace', () async {
      await db.categories.replace(const CategoriesCompanion(
          id: Value(3), description: Value('new name')));

      verify(executor.runUpdate(
          'UPDATE categories SET "desc" = ?, priority = 0 WHERE id = ?;',
          ['new name', 3]));
    });
  });
}
