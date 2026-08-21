import 'package:drift3_preview/drift.dart';
import 'package:test/test.dart';

import 'database.dart';

void main() {
  late TestDatabase db;

  setUp(() {
    db = TestDatabase.inMemory();
  });

  tearDown(() => db.close());

  test('manager - order', () async {
    await db.managers.tableWithEveryColumnType.create(
      (o) => o(
        id: Value(1),
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aReal: Value(5.0),
        aDateTime: Value(DateTime.now().add(Duration(days: 1))),
      ),
    );
    await db.managers.tableWithEveryColumnType.create(
      (o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aDateTime: Value(DateTime.now().add(Duration(days: 2))),
      ),
    );
    await db.managers.tableWithEveryColumnType.create(
      (o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aReal: Value(3.0),
        aDateTime: Value(DateTime.now().add(Duration(days: 3))),
      ),
    );

    // Equals
    expect(
      await db.managers.tableWithEveryColumnType
          .orderBy((o) => o.aDateTime.desc())
          .get()
          .then((value) => value[0].id),
      3,
    );
    expect(
      await db.managers.tableWithEveryColumnType
          .orderBy((o) => o.aDateTime.asc())
          .get()
          .then((value) => value[0].id),
      1,
    );
  });

  test('nulls first', () async {
    await db.managers.todosTable.bulkCreate(
      (o) => [
        o(content: 'a'),
        o(title: Value('first title'), content: 'b'),
        o(title: Value('second title'), content: 'c'),
      ],
    );

    final entries = await db.managers.todosTable
        .orderBy((o) => o.title.asc(nulls: NullsOrder.first))
        .get();
    expect(entries.map((e) => e.content), ['a', 'b', 'c']);
  });

  test('nulls last', () async {
    await db.managers.todosTable.bulkCreate(
      (o) => [
        o(title: Value('second title'), content: 'a'),
        o(title: Value('first title'), content: 'b'),
        o(content: 'c'),
      ],
    );

    final entries = await db.managers.todosTable
        .orderBy((o) => o.title.desc(nulls: NullsOrder.last))
        .get();
    expect(entries.map((e) => e.content), ['a', 'b', 'c']);
  });

  test('manager - order related', () async {
    final schoolCategoryId = await db.managers.categories.create(
      (o) => o(priority: Value(CategoryPriority.high), description: "School"),
    );
    final workCategoryId = await db.managers.categories.create(
      (o) => o(priority: Value(CategoryPriority.low), description: "Work"),
    );

    await db.managers.todosTable.create(
      (o) => o(
        id: Value(1),
        content: "Get that english homework done",
        title: Value("English Homework"),
        category: Value(workCategoryId),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 15))),
      ),
    );
    await db.managers.todosTable.create(
      (o) => o(
        id: Value(2),
        content: "Finish that Book report",
        title: Value("Book Report"),
        category: Value(workCategoryId),
        status: Value(TodoStatus.done),
        targetDate: Value(
          DateTime.now().subtract(Duration(days: 2, seconds: 15)),
        ),
      ),
    );
    await db.managers.todosTable.create(
      (o) => o(
        id: Value(3),
        content: "Get that math homework done",
        title: Value("Math Homework"),
        category: Value(schoolCategoryId),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 10))),
      ),
    );
    await db.managers.todosTable.create(
      (o) => o(
        id: Value(4),
        content: "Finish that report",
        title: Value("Report"),
        category: Value(schoolCategoryId),
        status: Value(TodoStatus.workInProgress),
        targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 10))),
      ),
    );
    // Order by related
    expect(
      await db.managers.todosTable
          .orderBy((o) => o.category.id.asc())
          .get()
          .then((value) => value.map((e) => e.id).toList()),
      [3, 4, 1, 2],
    );
  });
}
