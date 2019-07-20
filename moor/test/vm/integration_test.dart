import 'package:moor/moor.dart';
import 'package:test_api/test_api.dart';
import 'package:moor/moor_vm.dart';

import '../data/tables/todos.dart';

TodoDb db;

void main() {
  test('CRUD integration test', () async {
    db = TodoDb(VMDatabase.memory(logStatements: false));

    // write some dummy data
    await insertCategory();
    await insertUser();
    await insertTodos();

    await db.into(db.sharedTodos).insert(SharedTodo(todo: 2, user: 1));

    // test select statements
    final forUser = (await db.someDao.todosForUser(1)).single;
    expect(forUser.title, 'Another entry');

    // test delete statements
    await db.deleteTodoById(2);
    final queryAgain = await db.someDao.todosForUser(1);
    expect(queryAgain, isEmpty);

    // test update statements
    await (db.update(db.todosTable)..where((t) => t.id.equals(1)))
        .write(const TodosTableCompanion(content: Value('Updated content')));
    final readUpdated = await db.select(db.todosTable).getSingle();
    expect(readUpdated.content, 'Updated content');
  });
}

Future insertCategory() async {
  final forInsert = const CategoriesCompanion(description: Value('Work'));
  final row = Category(id: 1, description: 'Work');

  final id = await db.into(db.categories).insert(forInsert);
  expect(id, equals(1));

  final loaded = await db.select(db.categories).getSingle();
  expect(loaded, equals(row));
}

Future insertUser() async {
  final profilePic = Uint8List.fromList([1, 2, 3, 4, 5, 6]);
  final forInsert = UsersCompanion(
    name: const Value('Dashy McDashface'),
    isAwesome: const Value(true),
    profilePicture: Value(profilePic),
  );

  final id = await db.into(db.users).insert(forInsert);
  expect(id, equals(1));

  final user = await db.select(db.users).getSingle();
  expect(user.id, equals(1));
  expect(user.name, equals('Dashy McDashface'));
  expect(user.isAwesome, isTrue);
  expect(user.profilePicture, profilePic);
}

Future insertTodos() async {
  await db.into(db.todosTable).insertAll([
    TodosTableCompanion(
      title: const Value('A first entry'),
      content: const Value('Some content I guess'),
      targetDate: Value(DateTime(2019)),
    ),
    const TodosTableCompanion(
      title: Value('Another entry'),
      content: Value('this is a really creative test case'),
      category: Value(1), // "Work"
    ),
  ]);
}
