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

  test('generates insert statements', () async {
    await db.into(db.todosTable).insert(const TodosTableCompanion(
          content: Value('Implement insert statements'),
        ));

    verify(executor.runInsert('INSERT INTO todos (content) VALUES (?)',
        ['Implement insert statements']));
  });

  test('can insert floating point values', () async {
    // regression test for https://github.com/simolus3/moor/issues/30
    await db
        .into(db.tableWithoutPK)
        .insert(TableWithoutPKData(notReallyAnId: 42, someFloat: 3.1415));

    verify(executor.runInsert(
        'INSERT INTO table_without_p_k '
        '(not_really_an_id, some_float) VALUES (?, ?)',
        [42, 3.1415]));
  });

  test('generates insert or replace statements', () async {
    await db.into(db.todosTable).insert(
        TodoEntry(
          id: 113,
          content: 'Done',
        ),
        orReplace: true);

    verify(executor.runInsert(
        'INSERT OR REPLACE INTO todos (id, content) VALUES (?, ?)',
        [113, 'Done']));
  });

  test('runs bulk inserts', () async {
    await db.into(db.todosTable).insertAll(const [
      TodosTableCompanion(content: Value('a')),
      TodosTableCompanion(title: Value('title'), content: Value('b')),
      TodosTableCompanion(title: Value('title'), content: Value('c')),
    ]);

    final insertSimple = 'INSERT INTO todos (content) VALUES (?)';
    final insertTitle = 'INSERT INTO todos (title, content) VALUES (?, ?)';

    verify(executor.runBatched([
      BatchedStatement(insertSimple, [
        ['a']
      ]),
      BatchedStatement(insertTitle, [
        ['title', 'b'],
        ['title', 'c']
      ]),
    ]));

    verify(streamQueries.handleTableUpdates({db.todosTable}));
  });

  test('runs bulk inserts with OR REPLACE', () async {
    await db.into(db.todosTable).insertAll(const [
      TodosTableCompanion(content: Value('a')),
      TodosTableCompanion(title: Value('title'), content: Value('b')),
      TodosTableCompanion(title: Value('title'), content: Value('c')),
    ], orReplace: true);

    final insertSimple = 'INSERT OR REPLACE INTO todos (content) VALUES (?)';
    final insertTitle =
        'INSERT OR REPLACE INTO todos (title, content) VALUES (?, ?)';

    verify(executor.runBatched([
      BatchedStatement(insertSimple, [
        ['a']
      ]),
      BatchedStatement(insertTitle, [
        ['title', 'b'],
        ['title', 'c']
      ]),
    ]));

    verify(streamQueries.handleTableUpdates({db.todosTable}));
  });

  test('notifies stream queries on inserts', () async {
    await db.into(db.users).insert(UsersCompanion(
          name: const Value('User McUserface'),
          isAwesome: const Value(true),
          profilePicture: Value(Uint8List(0)),
        ));

    verify(streamQueries.handleTableUpdates({db.users}));
  });

  test('enforces data integrity', () {
    expect(
      db.into(db.todosTable).insert(
            const TodosTableCompanion(
              // not declared as nullable in table definition
              content: Value(null),
            ),
          ),
      throwsA(const TypeMatcher<InvalidDataException>()),
    );
  });

  test('reports auto-increment id', () async {
    when(executor.runInsert(any, any)).thenAnswer((_) => Future.value(42));

    expect(
      db
          .into(db.todosTable)
          .insert(const TodosTableCompanion(content: Value('Bottom text'))),
      completion(42),
    );
  });
}
