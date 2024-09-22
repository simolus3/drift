// ignore_for_file: unused_local_variable

import 'package:drift/drift.dart';
import 'package:drift/src/utils/async.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;

  setUp(() {
    db = TodoDb(testInMemoryDatabase());
  });

  tearDown(() => db.close());

  test('manager - query generic', () async {
    final categories =
        await _todoCategoryData.mapAsyncAndAwait((categoryData) async {
      await db.managers.categories.createReturning((o) => o(
          priority: categoryData.priority,
          id: Value(categoryData.id),
          description: categoryData.description));
    });
    final todos = await _todosData.mapAsyncAndAwait((todoData) async {
      await db.managers.todosTable.createReturning((o) => o(
          content: todoData.content,
          title: todoData.title,
          category: todoData.category,
          status: todoData.status,
          targetDate: todoData.targetDate));
    });
    final categoryIdAnnotation =
        db.managers.todosTable.annotation((a) => a.category.id);
    final todosInCategoryAnnotation =
        db.managers.todosTable.annotation((a) => a.category.id.count());
    final todosWithAnnotations = await db.managers.todosTable.withAnnotations(
        [categoryIdAnnotation, todosInCategoryAnnotation]).get();
    for (final (todo, an) in todosWithAnnotations) {
      final categoryId = categoryIdAnnotation.read(an);
      final todosInCategory = todosInCategoryAnnotation.read(an);
    }
  });
}

const _todoCategoryData = [
  (description: "School", priority: Value(CategoryPriority.high), id: RowId(1)),
  (description: "Work", priority: Value(CategoryPriority.low), id: RowId(2)),
];

final _todosData = <({
  Value<RowId> category,
  String content,
  Value<TodoStatus> status,
  Value<DateTime> targetDate,
  Value<String> title
})>[
  // School
  (
    content: "Get that math homework done",
    title: Value("Math Homework"),
    category: Value(_todoCategoryData[0].id),
    status: Value(TodoStatus.open),
    targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 10)))
  ),
  (
    content: "Finish that report",
    title: Value("Report"),
    category: Value(_todoCategoryData[0].id),
    status: Value(TodoStatus.workInProgress),
    targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 10)))
  ),
  (
    content: "Get that english homework done",
    title: Value("English Homework"),
    category: Value(_todoCategoryData[0].id),
    status: Value(TodoStatus.open),
    targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 15)))
  ),
  (
    content: "Finish that Book report",
    title: Value("Book Report"),
    category: Value(_todoCategoryData[0].id),
    status: Value(TodoStatus.done),
    targetDate: Value(DateTime.now().subtract(Duration(days: 2, seconds: 15)))
  ),
  // Work
  (
    content: "Clean the office",
    title: Value("Clean Office"),
    category: Value(_todoCategoryData[1].id),
    status: Value(TodoStatus.workInProgress),
    targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 20)))
  ),
  (
    content: "Nail that presentation",
    title: Value("Presentation"),
    category: Value(_todoCategoryData[1].id),
    status: Value(TodoStatus.open),
    targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 25)))
  ),
  (
    content: "Take a break",
    title: Value("Break"),
    category: Value(_todoCategoryData[1].id),
    status: Value(TodoStatus.done),
    targetDate: Value(DateTime.now().subtract(Duration(days: 2, seconds: 25)))
  ),
  // Items with no category
  (
    content: "Get Whiteboard",
    title: Value("Whiteboard"),
    status: Value(TodoStatus.open),
    targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 50))),
    category: Value.absent(),
  ),
  (
    category: Value.absent(),
    content: "Drink Water",
    title: Value("Water"),
    status: Value(TodoStatus.workInProgress),
    targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 50)))
  ),
];
