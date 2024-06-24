import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';
import '../utils/future_or_extension.dart';

void main() {
  late TodoDb db;

  setUp(() {
    db = TodoDb(testInMemoryDatabase());
  });

  tearDown(() => db.close());

  test('manager - order', () async {
    await db.managers.tableWithEveryColumnType.create((o) => o(
        id: Value(RowId(1)),
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aReal: Value(5.0),
        aDateTime: Value(DateTime.now().add(Duration(days: 1)))));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aDateTime: Value(DateTime.now().add(Duration(days: 2)))));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aReal: Value(3.0),
        aDateTime: Value(DateTime.now().add(Duration(days: 3)))));

    // Equals
    expect(
        db.managers.tableWithEveryColumnType
            .orderBy((o) => o.aDateTime.desc())
            .get()
            .toFuture()
            .then((value) => value[0].id),
        completion(3));
    expect(
        db.managers.tableWithEveryColumnType
            .orderBy((o) => o.aDateTime.asc())
            .get()
            .toFuture()
            .then((value) => value[0].id),
        completion(1));
  });

  test('manager - order related', () async {
    final schoolCategoryId = await db.managers.categories.create((o) =>
        o(priority: Value(CategoryPriority.high), description: "School"));
    final workCategoryId = await db.managers.categories.create(
        (o) => o(priority: Value(CategoryPriority.low), description: "Work"));

    await db.managers.todosTable.create((o) => o(
        id: Value(RowId(1)),
        content: "Get that english homework done",
        title: Value("English Homework"),
        category: Value(RowId(workCategoryId)),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 15)))));
    await db.managers.todosTable.create((o) => o(
        id: Value(RowId(2)),
        content: "Finish that Book report",
        title: Value("Book Report"),
        category: Value(RowId(workCategoryId)),
        status: Value(TodoStatus.done),
        targetDate:
            Value(DateTime.now().subtract(Duration(days: 2, seconds: 15)))));
    await db.managers.todosTable.create((o) => o(
        id: Value(RowId(3)),
        content: "Get that math homework done",
        title: Value("Math Homework"),
        category: Value(RowId(schoolCategoryId)),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 10)))));
    await db.managers.todosTable.create((o) => o(
        id: Value(RowId(4)),
        content: "Finish that report",
        title: Value("Report"),
        category: Value(RowId(schoolCategoryId)),
        status: Value(TodoStatus.workInProgress),
        targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 10)))));
    // Order by related
    expect(
        db.managers.todosTable
            .orderBy((o) => o.category.id.asc())
            .get()
            .toFuture()
            .then((value) => value.map((e) => e.id).toList()),
        completion([3, 4, 1, 2]));
  });
}
