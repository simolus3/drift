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

  test('subqueries', () async {
    await db.batch((batch) {
      batch.insertAll(db.categories, [
        CategoriesCompanion.insert(description: 'a'),
        CategoriesCompanion.insert(description: 'b'),
      ]);

      batch.insertAll(
        db.todosTable,
        [
          TodosTableCompanion.insert(content: 'aaaaa', category: Value(1)),
          TodosTableCompanion.insert(content: 'aa', category: Value(1)),
          TodosTableCompanion.insert(content: 'bbbbbb', category: Value(2)),
        ],
      );
    });

    // Now write a query returning the amount of content chars in each
    // category (written using subqueries).
    final subqueryContentLength = db.todosTable.content.length.sum();
    final subquery = Subquery(
        db.selectOnly(db.todosTable)
          ..addColumns([db.todosTable.category, subqueryContentLength])
          ..groupBy([db.todosTable.category]),
        's');

    final readableLength = subquery.ref(subqueryContentLength);
    final query = db.selectOnly(db.categories)
      ..addColumns([db.categories.id, readableLength])
      ..join([
        innerJoin(subquery,
            subquery.ref(db.todosTable.category).equalsExp(db.categories.id))
      ])
      ..orderBy([OrderingTerm.asc(db.categories.id)]);

    final rows = await query.get();
    expect(rows, hasLength(2));

    final first = rows[0];
    final second = rows[1];

    expect(first.read(db.categories.id), 1);
    expect(first.read(readableLength), 7);

    expect(second.read(db.categories.id), 2);
    expect(second.read(readableLength), 6);
  });
}
