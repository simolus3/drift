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

  test('can re-use an outer transaction', () async {
    await db.transaction(() async {
      await db.batch((b) {});
    });

    verifyNever(executor.runBatched(any));
    verify(executor.transactions.runBatched(any));
  });

  test('updates stream queries', () async {
    await db.batch((b) {
      b.update(db.users, const UsersCompanion(name: Value('new user name')));
    });

    verify(streamQueries.handleTableUpdates({db.users}));
  });
}
