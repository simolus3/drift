import 'package:collection/collection.dart';
import 'package:drift/drift.dart' hide isNull;
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
    expect(rows.isSorted((a, b) => a.id.id.compareTo(b.id.id)), isFalse);
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
          TodosTableCompanion.insert(
              content: 'aaaaa', category: Value(RowId(1))),
          TodosTableCompanion.insert(content: 'aa', category: Value(RowId(1))),
          TodosTableCompanion.insert(
              content: 'bbbbbb', category: Value(RowId(2))),
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

  test('compound statements', () async {
    await db.batch((batch) {
      batch.insertAll(db.categories, [
        CategoriesCompanion.insert(description: 'category'),
      ]);

      batch.insertAll(
        db.todosTable,
        [
          for (var i = 0; i < 2; i++)
            TodosTableCompanion.insert(content: 'a', category: Value(RowId(1))),
          for (var i = 0; i < 3; i++)
            TodosTableCompanion.insert(content: 'b', category: Value(null)),
        ],
      );
    });

    final count = subqueryExpression<int>(db.selectOnly(db.todosTable)
      ..addColumns([countAll()])
      ..where(db.todosTable.category.equalsExp(db.categories.id)));
    final countWithoutCategory =
        subqueryExpression<int>(db.selectOnly(db.todosTable)
          ..addColumns([countAll()])
          ..where(db.todosTable.category.isNull()));

    final query = db.selectOnly(db.categories)
      ..addColumns([db.categories.description, count])
      ..groupBy([db.categories.id]);
    query.unionAll(db.selectExpressions(
        [const Constant<String>(null), countWithoutCategory]));

    final [category, withoutCategory] = await query.get();
    expect(category.read(db.categories.description), 'category');
    expect(category.read(count), 2);

    expect(withoutCategory.read(db.categories.description), null);
    expect(withoutCategory.read(count), 3);
  });

  test('right outer join', () async {
    await db.categories
        .insertOne(CategoriesCompanion.insert(description: 'test'));

    final query = db.select(db.todosTable).join([
      rightOuterJoin(
          db.categories, db.categories.id.equalsExp(db.todosTable.category))
    ]);

    final row = await query.getSingle();
    expect(row.readTableOrNull(db.todosTable), isNull);
    expect(row.readTable(db.categories).description, 'test');
  });

  test('full outer join', () async {
    await db.todosTable.insertOne(TodosTableCompanion.insert(content: 'todo'));
    await db.categories
        .insertOne(CategoriesCompanion.insert(description: 'category'));

    final query = db.select(db.todosTable).join([
      fullOuterJoin(
          db.categories, db.categories.id.equalsExp(db.todosTable.category))
    ])
      ..orderBy([OrderingTerm.asc(db.todosTable.id, nulls: NullsOrder.first)]);

    final [a, b] = await query.get();
    expect(a.readTableOrNull(db.todosTable), isNull);
    expect(a.readTable(db.categories).description, 'category');

    expect(b.readTable(db.todosTable).content, 'todo');
    expect(b.readTableOrNull(db.categories), isNull);
  });
}
