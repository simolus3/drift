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
    await db.into(db.todosTable).insert(TodoEntry(
          content: 'Implement insert statements',
        ));

    verify(executor.runInsert('INSERT INTO todos (content) VALUES (?)',
        ['Implement insert statements']));
  });

  test('generates insert or replace statements', () async {
    await db.into(db.todosTable).insertOrReplace(TodoEntry(
          id: 113,
          content: 'Done',
        ));

    verify(executor.runInsert(
        'INSERT OR REPLACE INTO todos (id, content) VALUES (?, ?)',
        [113, 'Done']));
  });

  test('runs bulk inserts', () async {
    await db.into(db.todosTable).insertAll([
      TodoEntry(content: 'a'),
      TodoEntry(title: 'title', content: 'b'),
      TodoEntry(title: 'title', content: 'c'),
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

  test('notifies stream queries on inserts', () async {
    await db.into(db.users).insert(User(
          name: 'User McUserface',
          isAwesome: true,
          profilePicture: Uint8List(0),
        ));

    verify(streamQueries.handleTableUpdates({db.users}));
  });

  test('enforces data integrity', () {
    expect(
      db.into(db.todosTable).insert(
            TodoEntry(
              content: null, // not declared as nullable in table definition
            ),
          ),
      throwsA(const TypeMatcher<InvalidDataException>()),
    );
  });

  test('reports auto-increment id', () async {
    when(executor.runInsert(any, any)).thenAnswer((_) => Future.value(42));

    expect(db.into(db.todosTable).insert(TodoEntry(content: 'Bottom text')),
        completion(42));
  });
}
