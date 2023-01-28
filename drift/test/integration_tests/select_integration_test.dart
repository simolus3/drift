import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;

  setUp(() {
    db = TodoDb(testInMemoryDatabase());
  });

  tearDown(() => db.close());

  test('can use random ordering', () async {
    await db.batch((b) {
      b.insertAll(db.users, [
        for (var i = 0; i < 1000; i++)
          UsersCompanion.insert(
              name: 'user name $i', profilePicture: Uint8List(0)),
      ]);
    });

    final rows = await (db.select(db.users)
          ..orderBy([(_) => OrderingTerm.random()]))
        .get();
    expect(rows.isSorted((a, b) => a.id.compareTo(b.id)), isFalse);
  });

  test('can select view', () async {
    final category = await db.categories.insertReturning(
        CategoriesCompanion.insert(description: 'category description'));
    await db.todosTable.insertOne(TodosTableCompanion.insert(
        content: 'some content',
        title: const Value('title'),
        category: Value(category.id)));

    final result = await db.todoWithCategoryView.select().getSingle();
    expect(
        result,
        const TodoWithCategoryViewData(
            description: 'category description', title: 'title'));
  });

  test('all()', () async {
    final user = await db.users.insertReturning(
        UsersCompanion.insert(name: 'Test user', profilePicture: Uint8List(0)));

    expect(await db.users.all().get(), [user]);
  });
}
