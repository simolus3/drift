import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late TodoDb db;

  setUp(() {
    db = TodoDb(testInMemoryDatabase());
  });

  //   // Create a dataset for the tests
  //   schoolId = await db.managers.categories.create((o) =>
  //       o(priority: Value(CategoryPriority.high), description: "School"));
  //   workId = await db.managers.categories.create(
  //       (o) => o(priority: Value(CategoryPriority.low), description: "Work"));
  //   homeId = await db.managers.categories.create((o) =>
  //       o(priority: Value(CategoryPriority.medium), description: "Home"));
  //   otherId = await db.managers.categories.create(
  //       (o) => o(priority: Value(CategoryPriority.high), description: "Other"));

  //   // School
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Get that math homework done",
  //       title: Value("Math Homework"),
  //       category: Value(schoolId),
  //       status: Value(TodoStatus.open),
  //       targetDate: Value(DateTime.now().add(Duration(days: 1,seconds: 10)))));
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Finish that report",
  //       title: Value("Report"),
  //       category: Value(workId),
  //       status: Value(TodoStatus.workInProgress),
  //       targetDate: Value(DateTime.now().add(Duration(days: 2,seconds: 10)))));
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Get that english homework done",
  //       title: Value("English Homework"),
  //       category: Value(schoolId),
  //       status: Value(TodoStatus.open),
  //       targetDate: Value(DateTime.now().add(Duration(days: 1,seconds: 15)))));
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Finish that Book report",
  //       title: Value("Book Report"),
  //       category: Value(workId),
  //       status: Value(TodoStatus.done),
  //       targetDate: Value(DateTime.now().subtract(Duration(days: 2,seconds: 15)))));

  //   // Work
  //   await db.managers.todosTable.create((o) => o(
  //       content: "File those reports",
  //       title: Value("File Reports"),
  //       category: Value(workId),
  //       status: Value(TodoStatus.open),
  //       targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 20)))););
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Clean the office",
  //       title: Value("Clean Office"),
  //       category: Value(workId),
  //       status: Value(TodoStatus.workInProgress),
  //       targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 20)))););
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Nail that presentation",
  //       title: Value("Presentation"),
  //       category: Value(workId),
  //       status: Value(TodoStatus.open),
  //       targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 25)))));
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Take a break",
  //       title: Value("Break"),
  //       category: Value(workId),
  //       status: Value(TodoStatus.done),
  //       targetDate: Value(DateTime.now().subtract(Duration(days: 2, seconds: 25)))));

  //   // Work
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Take out the trash",
  //       title: Value("Trash"),
  //       category: Value(homeId),
  //       status: Value(TodoStatus.open),
  //       targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 30)))););
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Mow the lawn",
  //       title: Value("Lawn"),
  //       category: Value(homeId),
  //       status: Value(TodoStatus.workInProgress),
  //       targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 30)))));
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Fix the sink",
  //       title: Value("Sink"),
  //       category: Value(homeId),
  //       status: Value(TodoStatus.open),
  //       targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 35)))););
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Paint the walls",
  //       title: Value("Paint"),
  //       category: Value(homeId),
  //       status: Value(TodoStatus.done),
  //       targetDate: Value(DateTime.now().subtract(Duration(days: 2, seconds: 35)))));

  //   // Other
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Get groceries",
  //       title: Value("Groceries"),
  //       category: Value(otherId),
  //       status: Value(TodoStatus.open),
  //       targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 40)))););
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Pick up the kids",
  //       title: Value("Kids"),
  //       category: Value(otherId),
  //       status: Value(TodoStatus.workInProgress),
  //       targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 40)))););
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Take the dog for a walk",
  //       title: Value("Dog"),
  //       category: Value(otherId),
  //       status: Value(TodoStatus.open),
  //       targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 45)))));

  //   // Items with no category
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Get Whiteboard",
  //       title: Value("Whiteboard"),
  //       status: Value(TodoStatus.open),
  //       targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 50)))););
  //   await db.managers.todosTable.create((o) => o(
  //       content: "Drink Water",
  //       title: Value("Water"),
  //       status: Value(TodoStatus.workInProgress),
  //       targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 50)))));
  // });

  tearDown(() => db.close());

  test('manager - query generic', () async {
    await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open),
        someFloat: Value(5.0),
        targetDate: Value(DateTime.now().add(Duration(days: 1)))));
    await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 2)))));
    await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open),
        someFloat: Value(3.0),
        targetDate: Value(DateTime.now().add(Duration(days: 3)))));

    // Equals
    expect(
        db.managers.todosTable.filter((f) => f.someFloat.equals(5.0)).count(),
        completion(1));
    expect(db.managers.todosTable.filter((f) => f.someFloat(3.0)).count(),
        completion(1));
    // In
    expect(
        db.managers.todosTable
            .filter((f) => f.someFloat.isIn([3.0, 5.0]))
            .count(),
        completion(2));

    // Not In
    expect(
        db.managers.todosTable
            .filter((f) => f.someFloat.isNotIn([3.0, 5.0]))
            .count(),
        completion(0));

    // Null check
    expect(db.managers.todosTable.filter((f) => f.someFloat.isNull()).count(),
        completion(1));
    expect(
        db.managers.todosTable.filter((f) => f.someFloat.isNotNull()).count(),
        completion(2));
  });

  test('manager - query number', () async {
    final objId1 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open),
        someFloat: Value(5.0),
        targetDate: Value(DateTime.now().add(Duration(days: 1)))));
    final objId2 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 2)))));
    final objId3 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open),
        someFloat: Value(3.0),
        targetDate: Value(DateTime.now().add(Duration(days: 3)))));

    // More than
    expect(
        db.managers.todosTable
            .filter((f) => f.someFloat.isBiggerThan(3.0))
            .count(),
        completion(1));
    expect(
        db.managers.todosTable
            .filter((f) => f.someFloat.isBiggerOrEqualTo(3.0))
            .count(),
        completion(2));

    // Less than
    expect(
        db.managers.todosTable
            .filter((f) => f.someFloat.isSmallerThan(5.0))
            .count(),
        completion(1));
    expect(
        db.managers.todosTable
            .filter((f) => f.someFloat.isSmallerOrEqualTo(5.0))
            .count(),
        completion(2));

    // Between
    expect(
        db.managers.todosTable
            .filter((f) => f.someFloat.isBetween(3.0, 5.0))
            .count(),
        completion(2));
    expect(
        db.managers.todosTable
            .filter((f) => f.someFloat.isNotBetween(3.0, 5.0))
            .count(),
        completion(0));
  });

  test('manager - query string', () async {
    await db.managers.todosTable.create((o) => o(
          content: "Get that math homework done",
          status: Value(TodoStatus.open),
        ));
    await db.managers.todosTable.create((o) => o(
          content: "That homework Done",
        ));
    await db.managers.todosTable.create((o) => o(
          content: "that MATH homework",
          status: Value(TodoStatus.open),
        ));

    // StartsWith
    expect(
        db.managers.todosTable
            .filter((f) => f.content.startsWith("that"))
            .count(),
        completion(2));

    // EndsWith
    expect(
        db.managers.todosTable
            .filter((f) => f.content.endsWith("done"))
            .count(),
        completion(2));

    // Contains
    expect(
        db.managers.todosTable
            .filter((f) => f.content.contains("math"))
            .count(),
        completion(2));

    // Make the database case sensitive
    await db.customStatement('PRAGMA case_sensitive_like = ON');

    // StartsWith
    expect(
        db.managers.todosTable
            .filter((f) => f.content.startsWith("that", caseInsensitive: false))
            .count(),
        completion(1));

    // EndsWith
    expect(
        db.managers.todosTable
            .filter((f) => f.content.endsWith("done", caseInsensitive: false))
            .count(),
        completion(1));

    // Contains
    expect(
        db.managers.todosTable
            .filter((f) => f.content.contains("math", caseInsensitive: false))
            .count(),
        completion(1));
  });

  test('manager - query int64', () async {
    final objId1 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open),
        someInt64: Value(BigInt.from(5.0)),
        targetDate: Value(DateTime.now().add(Duration(days: 1)))));
    final objId2 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 2)))));
    final objId3 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open),
        someInt64: Value(BigInt.from(3.0)),
        targetDate: Value(DateTime.now().add(Duration(days: 3)))));

    // More than
    expect(
        db.managers.todosTable
            .filter((f) => f.someInt64.isBiggerThan(BigInt.from(3.0)))
            .count(),
        completion(1));
    expect(
        db.managers.todosTable
            .filter((f) => f.someInt64.isBiggerOrEqualTo(BigInt.from(3.0)))
            .count(),
        completion(2));

    // Less than
    expect(
        db.managers.todosTable
            .filter((f) => f.someInt64.isSmallerThan(BigInt.from(5.0)))
            .count(),
        completion(1));
    expect(
        db.managers.todosTable
            .filter((f) => f.someInt64.isSmallerOrEqualTo(BigInt.from(5.0)))
            .count(),
        completion(2));

    // Between
    expect(
        db.managers.todosTable
            .filter((f) =>
                f.someInt64.isBetween(BigInt.from(3.0), BigInt.from(5.0)))
            .count(),
        completion(2));
    expect(
        db.managers.todosTable
            .filter((f) =>
                f.someInt64.isNotBetween(BigInt.from(3.0), BigInt.from(5.0)))
            .count(),
        completion(0));
  });

  test('manager - query bool', () async {
    final objId1 = await db.managers.users.create((o) => o(
        name: "John Doe",
        profilePicture: Uint8List(0),
        isAwesome: Value(true),
        creationTime: Value(DateTime.now().add(Duration(days: 1)))));
    final objId2 = await db.managers.users.create((o) => o(
        name: "Jane Doe1",
        profilePicture: Uint8List(0),
        isAwesome: Value(false),
        creationTime: Value(DateTime.now().add(Duration(days: 2)))));
    final objId3 = await db.managers.users.create((o) => o(
        name: "Jane Doe2",
        profilePicture: Uint8List(0),
        isAwesome: Value(true),
        creationTime: Value(DateTime.now().add(Duration(days: 2)))));

    // False
    expect(db.managers.users.filter((f) => f.isAwesome.isFalse()).count(),
        completion(1));
    // True
    expect(db.managers.users.filter((f) => f.isAwesome.isTrue()).count(),
        completion(2));
  });

  test('manager - query datetime', () async {
    final day1 = DateTime.now().add(Duration(days: 1));
    final day2 = DateTime.now().add(Duration(days: 2));
    final day3 = DateTime.now().add(Duration(days: 3));
    final objId1 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open),
        someFloat: Value(5.0),
        targetDate: Value(day1)));
    final objId2 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open),
        targetDate: Value(day2)));
    final objId3 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open),
        someFloat: Value(3.0),
        targetDate: Value(day3)));

    // More than
    expect(
        db.managers.todosTable
            .filter((f) => f.targetDate.isAfter(day2))
            .count(),
        completion(1));
    expect(
        db.managers.todosTable
            .filter((f) => f.targetDate.isAfterOrOn(day2))
            .count(),
        completion(2));

    // Less than
    expect(
        db.managers.todosTable
            .filter((f) => f.targetDate.isBefore(day2))
            .count(),
        completion(1));
    expect(
        db.managers.todosTable
            .filter((f) => f.targetDate.isBeforeOrOn(day2))
            .count(),
        completion(2));

    // Between
    expect(
        db.managers.todosTable
            .filter((f) => f.targetDate.isBetween(day1, day2))
            .count(),
        completion(2));
    expect(
        db.managers.todosTable
            .filter((f) => f.targetDate.isNotBetween(day1, day2))
            .count(),
        completion(1));
  });

  test('manager - query custom column', () async {
    final objId1 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open)));
    final objId2 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.open)));
    final objId3 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.workInProgress)));
    final objId4 = await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        status: Value(TodoStatus.done)));

    // Equals
    expect(
        db.managers.todosTable
            .filter((f) => f.status.equals(TodoStatus.open))
            .count(),
        completion(2));
    expect(
        db.managers.todosTable.filter((f) => f.status(TodoStatus.open)).count(),
        completion(2));

    // In
    expect(
        db.managers.todosTable
            .filter((f) =>
                f.status.isIn([TodoStatus.open, TodoStatus.workInProgress]))
            .count(),
        completion(3));

    // Not In
    expect(
        db.managers.todosTable
            .filter((f) =>
                f.status.isNotIn([TodoStatus.open, TodoStatus.workInProgress]))
            .count(),
        completion(1));
  });
}
