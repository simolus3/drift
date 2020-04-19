import 'package:moor/moor.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;
  MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();

    db = TodoDb.connect(createConnection(executor, streamQueries));
  });

  test('runs generated statements', () async {
    await db.batch((b) {
      b.insertAll(
        db.todosTable,
        [
          TodosTableCompanion.insert(content: 'first'),
          TodosTableCompanion.insert(content: 'second'),
        ],
      );

      b.update(db.users, const UsersCompanion(name: Value('new name')));
      b.update(
        db.users,
        const UsersCompanion(name: Value('Another')),
        where: (Users row) => row.name.equals('old'),
      );

      b.replaceAll(db.categories, const [
        CategoriesCompanion(id: Value(1), description: Value('new1')),
        CategoriesCompanion(id: Value(2), description: Value('new2')),
      ]);

      b.deleteWhere(db.categories, (_) => const Constant(true));
      b.delete(db.todosTable, const TodosTableCompanion(id: Value(3)));
    });

    final transaction = executor.transactions;
    verify(transaction.runBatched([
      BatchedStatement(
        'INSERT INTO todos (content) VALUES (?)',
        [
          ['first'],
          ['second'],
        ],
      ),
      BatchedStatement(
        'UPDATE users SET name = ?;',
        [
          ['new name']
        ],
      ),
      BatchedStatement(
        'UPDATE users SET name = ? WHERE name = ?;',
        [
          ['Another', 'old']
        ],
      ),
      BatchedStatement(
        'UPDATE categories SET desc = ? WHERE id = ?;',
        [
          ['new1', 1],
          ['new2', 2],
        ],
      ),
      BatchedStatement(
        'DELETE FROM categories WHERE 1;',
        [[]],
      ),
      BatchedStatement(
        'DELETE FROM todos WHERE id = ?;',
        [
          [3]
        ],
      ),
    ]));
  });

  test('supports inserts with upsert clause', () async {
    await db.batch((batch) {
      batch.insert(
        db.categories,
        CategoriesCompanion.insert(description: 'description'),
        onConflict: DoUpdate((old) {
          return const CategoriesCompanion(id: Value(42));
        }),
      );
    });

    verify(executor.transactions.runBatched([
      BatchedStatement(
        'INSERT INTO categories (`desc`) VALUES (?) '
        'ON CONFLICT DO UPDATE SET id = ?',
        [
          ['description', 42]
        ],
      ),
    ]));
  });

  test('insertAllOnConflictUpdate', () async {
    final entries = [
      CategoriesCompanion.insert(description: 'first'),
      CategoriesCompanion.insert(description: 'second'),
    ];

    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.categories, entries);
    });

    verify(executor.transactions.runBatched([
      BatchedStatement(
        'INSERT INTO categories (`desc`) VALUES (?) '
        'ON CONFLICT DO UPDATE SET `desc` = ?',
        [
          ['first', 'first'],
          ['second', 'second'],
        ],
      ),
    ]));
  });

  test('can re-use an outer transaction', () async {
    await db.transaction(() async {
      await db.batch((b) {});
    });

    verifyNever(executor.runBatched(any));
    verify(executor.transactions.runBatched(any));
  }, onPlatform: const {
    'js': [Skip('Blocked by https://github.com/dart-lang/mockito/issues/198')]
  });

  test('supports async batch functions', () async {
    await db.batch((batch) async {
      batch.insert(
          db.categories, CategoriesCompanion.insert(description: 'first'));

      await Future.delayed(Duration.zero);

      batch.insert(
          db.categories, CategoriesCompanion.insert(description: 'second'));
    });

    verify(executor.transactions.runBatched([
      BatchedStatement('INSERT INTO categories (`desc`) VALUES (?)', [
        ['first'],
        ['second']
      ]),
    ]));
  });

  test('updates stream queries', () async {
    await db.batch((b) {
      b.insert(db.todosTable, TodoEntry(id: 3, content: 'content'));

      b.update(db.users, const UsersCompanion(name: Value('new user name')));
      b.replace(
        db.todosTable,
        const TodosTableCompanion(id: Value(3), content: Value('new')),
      );

      b.deleteWhere(db.todosTable, (TodosTable row) => row.id.equals(3));
      b.delete(db.todosTable, const TodosTableCompanion(id: Value(3)));
    });

    verify(
      streamQueries.handleTableUpdates({
        const TableUpdate('todos', kind: UpdateKind.insert),
        const TableUpdate('users', kind: UpdateKind.update),
        const TableUpdate('todos', kind: UpdateKind.update),
        const TableUpdate('todos', kind: UpdateKind.delete),
      }),
    );
  });
}
