// ignore_for_file: unused_local_variable

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

  test('manager - query generic', () async {
    await db.managers.tableWithEveryColumnType.create((o) => o(
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
            .filter((f) => f.aReal.equals(5.0))
            .count(),
        completion(1));
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal(3.0))
            .count(),
        completion(1));

    // Not Equals - Exclude null (Default behavior)
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.not.equals(5.0))
            .count(),
        completion(1));

    // In
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isIn([3.0, 5.0]))
            .count(),
        completion(2));

    // Not In
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.not.isIn([3.0, 5.0]))
            .count(),
        completion(0));

    // Null check
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isNull())
            .count(),
        completion(1));

    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.not.isNull())
            .count(),
        completion(2));
  });

  test('manager - query number', () async {
    await db.managers.tableWithEveryColumnType.create((o) => o(
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

    // More than
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isBiggerThan(3.0))
            .count(),
        completion(1));
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isBiggerOrEqualTo(3.0))
            .count(),
        completion(2));

    // Less than
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isSmallerThan(5.0))
            .count(),
        completion(1));
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isSmallerOrEqualTo(5.0))
            .count(),
        completion(2));

    // Between
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isBetween(3.0, 5.0))
            .count(),
        completion(2));
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.not.isBetween(3.0, 5.0))
            .count(),
        completion(0));
  });

  test('manager - query string', () async {
    await db.managers.tableWithEveryColumnType.create((o) => o(
          aText: Value("Get that math homework done"),
          anIntEnum: Value(TodoStatus.open),
        ));
    await db.managers.tableWithEveryColumnType.create((o) => o(
          aText: Value("That homework Done"),
        ));
    await db.managers.tableWithEveryColumnType.create((o) => o(
          aText: Value("that MATH homework"),
          anIntEnum: Value(TodoStatus.open),
        ));

    // StartsWith
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aText.startsWith("that"))
            .count(),
        completion(2));

    // EndsWith
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aText.endsWith("done"))
            .count(),
        completion(2));

    // Contains
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aText.contains("math"))
            .count(),
        completion(2));

    // Make the database case sensitive
    await db.customStatement('PRAGMA case_sensitive_like = ON');

    // StartsWith
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aText.startsWith("that", caseInsensitive: false))
            .count(),
        completion(1));

    // EndsWith
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aText.endsWith("done", caseInsensitive: false))
            .count(),
        completion(1));

    // Contains
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aText.contains("math", caseInsensitive: false))
            .count(),
        completion(1));
  });

  test('manager - query int64', () async {
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        anInt64: Value(BigInt.from(5.0)),
        aDateTime: Value(DateTime.now().add(Duration(days: 1)))));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aDateTime: Value(DateTime.now().add(Duration(days: 2)))));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        anInt64: Value(BigInt.from(3.0)),
        aDateTime: Value(DateTime.now().add(Duration(days: 3)))));

    // More than
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.anInt64.isBiggerThan(BigInt.from(3.0)))
            .count(),
        completion(1));
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.anInt64.isBiggerOrEqualTo(BigInt.from(3.0)))
            .count(),
        completion(2));

    // Less than
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.anInt64.isSmallerThan(BigInt.from(5.0)))
            .count(),
        completion(1));
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.anInt64.isSmallerOrEqualTo(BigInt.from(5.0)))
            .count(),
        completion(2));

    // Between
    expect(
        db.managers.tableWithEveryColumnType
            .filter(
                (f) => f.anInt64.isBetween(BigInt.from(3.0), BigInt.from(5.0)))
            .count(),
        completion(2));
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) =>
                f.anInt64.not.isBetween(BigInt.from(3.0), BigInt.from(5.0)))
            .count(),
        completion(0));
  });

  test('manager - query bool', () async {
    await db.managers.users.create((o) => o(
        name: "John Doe",
        profilePicture: Uint8List(0),
        isAwesome: Value(true),
        creationTime: Value(DateTime.now().add(Duration(days: 1)))));
    await db.managers.users.create((o) => o(
        name: "Jane Doe1",
        profilePicture: Uint8List(0),
        isAwesome: Value(false),
        creationTime: Value(DateTime.now().add(Duration(days: 2)))));
    await db.managers.users.create((o) => o(
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
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aReal: Value(5.0),
        aDateTime: Value(day1)));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aDateTime: Value(day2)));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aReal: Value(3.0),
        aDateTime: Value(day3)));

    // More than
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aDateTime.isAfter(day2))
            .count(),
        completion(1));
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aDateTime.isAfterOrOn(day2))
            .count(),
        completion(2));

    // Less than
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aDateTime.isBefore(day2))
            .count(),
        completion(1));
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aDateTime.isBeforeOrOn(day2))
            .count(),
        completion(2));

    // Between
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aDateTime.isBetween(day1, day2))
            .count(),
        completion(2));
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.aDateTime.not.isBetween(day1, day2))
            .count(),
        completion(1));
  });

  test('manager - query custom column', () async {
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open)));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open)));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.workInProgress)));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.done)));
    await db.managers.tableWithEveryColumnType
        .create((o) => o(aText: Value("Get that math homework done")));

    // Equals
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.anIntEnum.equals(TodoStatus.open))
            .count(),
        completion(2));
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.anIntEnum(TodoStatus.open))
            .count(),
        completion(2));

    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.anIntEnum.not(TodoStatus.open))
            .count(),
        completion(2));

    // Not Equals
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.anIntEnum.not.equals(TodoStatus.open))
            .count(),
        completion(2));

    // In
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) =>
                f.anIntEnum.isIn([TodoStatus.open, TodoStatus.workInProgress]))
            .count(),
        completion(3));

    // Not In
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.anIntEnum.not
                .isIn([TodoStatus.open, TodoStatus.workInProgress]))
            .count(),
        completion(1));
  });

  test('manager - filter related', () async {
    final bookClubA =
        await db.managers.bookClub.create((o) => o(name: Value("Book Club A")));
    final bookClubB =
        await db.managers.bookClub.create((o) => o(name: Value("Book Club B")));

    final member1 = await db.managers.person
        .create((o) => o(name: Value("John Doe"), club: Value(bookClubA)));
    final member2 = await db.managers.person
        .create((o) => o(name: Value("Jane Doe"), club: Value(bookClubA)));
    final member3 = await db.managers.person
        .create((o) => o(name: Value("John Smith"), club: Value(bookClubB)));
    final member4 = await db.managers.person
        .create((o) => o(name: Value("Jane Smith"), club: Value(bookClubB)));
    final member5 = await db.managers.person
        .create((o) => o(name: Value("Martha Smith"), club: Value(bookClubB)));

    final book1 = await db.managers.book.create((o) => o(
        title: Value("Book 1"),
        author: Value(member1),
        publisher: Value(member2)));
    final book2 = await db.managers.book.create((o) => o(
        title: Value("Book 2"),
        author: Value(member3),
        publisher: Value(member4)));
    final book3 = await db.managers.book.create((o) => o(
        title: Value("Book 3"),
        author: Value(member1),
        publisher: Value(member4)));
    final book4 = await db.managers.book.create((o) => o(
        title: Value("Book 4"),
        author: Value(member2),
        publisher: Value(member3)));

    // item without title

    // Equals - ID
    expect(db.managers.person.filter((f) => f.club.id(bookClubA)).count(),
        completion(2));

    // Not Equals - ID
    expect(db.managers.person.filter((f) => f.club.id.not(bookClubA)).count(),
        completion(3));

    // Equals - Other column
    expect(db.managers.person.filter((f) => f.club.name("Book Club A")).count(),
        completion(2));

    // Not Equals - Other column
    expect(
        db.managers.person
            .filter((f) => f.club.name.not("Book Club A"))
            .count(),
        completion(3));

    // Multiple filters
    expect(
        db.managers.person
            .filter((f) => f.club.id(bookClubA))
            .filter((f) => f.name.startsWith("Jane"))
            .count(),
        completion(1));
    expect(
        db.managers.person
            .filter((f) => f.club.id(bookClubA) & f.name.startsWith("Jane"))
            .count(),
        completion(1));
    expect(
        db.managers.person
            .filter((f) => f.club.id(bookClubA) | f.name.startsWith("Jane"))
            .count(),
        completion(3));

    // Multiple use related filters twice
    expect(
        db.managers.person
            .filter((f) =>
                f.club.name("Book Club A") |
                f.publishedBooks((f) => f.id(book2)).any())
            .count(),
        completion(3));

    expect(
        db.managers.person
            .filter(
                (f) => f.club.name("Book Club A") | f.club.name("Book Club B"))
            .count(),
        completion(5));

    // Use backreference
    expect(
        db.managers.person
            .filter((f) => f.publishedBooks((f) => f.id(book2)).any())
            .count(),
        completion(1));

    // // Use forward reference on a single id, this should not use a join
    ComposableFilter? filter;
    expect(
        db.managers.person.filter((f) {
          final t = f.club.id(bookClubA);
          filter = t;
          return t;
        }).count(),
        completion(2));
    expect(filter?.joinBuilders.length, 0);

    // Nested backreference
    expect(
        db.managers.bookClub
            .filter((f) => f
                .personRefs((f) =>
                    f.club.personRefs((f) => f.name.equals("John Doe")).any())
                .any())
            .count(),
        completion(1));
  });
  test('manager - filter related with custom type for primary key', () async {
    final schoolCategoryId = await db.managers.categories.create((o) =>
        o(priority: Value(CategoryPriority.high), description: "School"));
    final workCategoryId = await db.managers.categories.create(
        (o) => o(priority: Value(CategoryPriority.low), description: "Work"));

    // School
    await db.managers.todosTable.create((o) => o(
        content: "Get that math homework done",
        title: Value("Math Homework"),
        category: Value(schoolCategoryId),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 10)))));
    await db.managers.todosTable.create((o) => o(
        content: "Finish that report",
        title: Value("Report"),
        category: Value(schoolCategoryId),
        status: Value(TodoStatus.workInProgress),
        targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 10)))));
    await db.managers.todosTable.create((o) => o(
        content: "Get that english homework done",
        title: Value("English Homework"),
        category: Value(schoolCategoryId),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 15)))));
    await db.managers.todosTable.create((o) => o(
        content: "Finish that Book report",
        title: Value("Book Report"),
        category: Value(schoolCategoryId),
        status: Value(TodoStatus.done),
        targetDate:
            Value(DateTime.now().subtract(Duration(days: 2, seconds: 15)))));

    // Work
    await db.managers.todosTable.create((o) => o(
        content: "File those reports",
        title: Value("File Reports"),
        category: Value(workCategoryId),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 20)))));
    await db.managers.todosTable.create((o) => o(
        content: "Clean the office",
        title: Value("Clean Office"),
        category: Value(workCategoryId),
        status: Value(TodoStatus.workInProgress),
        targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 20)))));
    await db.managers.todosTable.create((o) => o(
        content: "Nail that presentation",
        title: Value("Presentation"),
        category: Value(workCategoryId),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 25)))));
    await db.managers.todosTable.create((o) => o(
        content: "Take a break",
        title: Value("Break"),
        category: Value(workCategoryId),
        status: Value(TodoStatus.done),
        targetDate:
            Value(DateTime.now().subtract(Duration(days: 2, seconds: 25)))));

    // Items with no category
    await db.managers.todosTable.create((o) => o(
        content: "Get Whiteboard",
        title: Value("Whiteboard"),
        status: Value(TodoStatus.open),
        targetDate: Value(DateTime.now().add(Duration(days: 1, seconds: 50)))));
    await db.managers.todosTable.create((o) => o(
        content: "Drink Water",
        title: Value("Water"),
        status: Value(TodoStatus.workInProgress),
        targetDate: Value(DateTime.now().add(Duration(days: 2, seconds: 50)))));

    // item without title

    // Equals
    expect(
        db.managers.todosTable
            .filter((f) => f.category.id(RowId(schoolCategoryId)))
            .count(),
        completion(4));

    // Not Equals
    expect(
        db.managers.todosTable
            .filter((f) => f.category.id.not(RowId(schoolCategoryId)))
            .count(),
        completion(4));

    // Multiple filters
    expect(
        db.managers.todosTable
            .filter((f) => f.category.id(
                  RowId(schoolCategoryId),
                ))
            .filter((f) => f.status.equals(TodoStatus.open))
            .count(),
        completion(2));

    // Multiple use related filters twice
    expect(
        db.managers.todosTable
            .filter((f) =>
                f.category.priority(CategoryPriority.low) |
                f.category.descriptionInUpperCase("SCHOOL"))
            .count(),
        completion(8));

    // Use .filter multiple times
    expect(
        db.managers.todosTable
            .filter((f) => f.category.priority.equals(CategoryPriority.high))
            .filter((f) => f.category.descriptionInUpperCase("SCHOOL"))
            .count(),
        completion(4));

    // Use backreference
    expect(
        db.managers.categories
            .filter(
                (f) => f.todos((f) => f.title.equals("Math Homework")).any())
            .getSingle()
            .then((value) => value.description),
        completion("School"));

    // Nested backreference
    expect(
        db.managers.categories
            .filter((f) => f
                .todos((f) => f.category
                    .todos((f) => f.title.equals("Math Homework"))
                    .any())
                .any())
            .getSingle()
            .then((value) => value.description),
        completion("School"));
  });
}
