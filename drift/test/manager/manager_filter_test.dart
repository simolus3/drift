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
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.equals(5.0))
            .count(),
        1);
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal(3.0))
            .count(),
        1);

    // Not Equals - Exclude null (Default behavior)
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.not.equals(5.0))
            .count(),
        1);

    // In
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isIn([3.0, 5.0]))
            .count(),
        2);

    // Not In
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.not.isIn([3.0, 5.0]))
            .count(),
        0);

    // Null check
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isNull())
            .count(),
        1);

    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.not.isNull())
            .count(),
        2);
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
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isBiggerThan(3.0))
            .count(),
        1);
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isBiggerOrEqualTo(3.0))
            .count(),
        2);

    // Less than
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isSmallerThan(5.0))
            .count(),
        1);
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isSmallerOrEqualTo(5.0))
            .count(),
        2);

    // Between
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.isBetween(3.0, 5.0))
            .count(),
        2);
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aReal.not.isBetween(3.0, 5.0))
            .count(),
        0);
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
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aText.startsWith("that"))
            .count(),
        2);

    // EndsWith
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aText.endsWith("done"))
            .count(),
        2);

    // Contains
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aText.contains("math"))
            .count(),
        2);

    // Make the database case sensitive
    await db.customStatement('PRAGMA case_sensitive_like = ON');

    // StartsWith
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aText.startsWith("that", caseInsensitive: false))
            .count(),
        1);

    // EndsWith
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aText.endsWith("done", caseInsensitive: false))
            .count(),
        1);

    // Contains
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aText.contains("math", caseInsensitive: false))
            .count(),
        1);
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
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.anInt64.isBiggerThan(BigInt.from(3.0)))
            .count(),
        1);
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.anInt64.isBiggerOrEqualTo(BigInt.from(3.0)))
            .count(),
        2);

    // Less than
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.anInt64.isSmallerThan(BigInt.from(5.0)))
            .count(),
        1);
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.anInt64.isSmallerOrEqualTo(BigInt.from(5.0)))
            .count(),
        2);

    // Between
    expect(
        await db.managers.tableWithEveryColumnType
            .filter(
                (f) => f.anInt64.isBetween(BigInt.from(3.0), BigInt.from(5.0)))
            .count(),
        2);
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) =>
                f.anInt64.not.isBetween(BigInt.from(3.0), BigInt.from(5.0)))
            .count(),
        0);
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
    expect(await db.managers.users.filter((f) => f.isAwesome.isFalse()).count(),
        1);
    // True
    expect(
        await db.managers.users.filter((f) => f.isAwesome.isTrue()).count(), 2);
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
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aDateTime.isAfter(day2))
            .count(),
        1);
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aDateTime.isAfterOrOn(day2))
            .count(),
        2);

    // Less than
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aDateTime.isBefore(day2))
            .count(),
        1);
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aDateTime.isBeforeOrOn(day2))
            .count(),
        2);

    // Between
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aDateTime.isBetween(day1, day2))
            .count(),
        2);
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aDateTime.not.isBetween(day1, day2))
            .count(),
        1);
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
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.anIntEnum.equals(TodoStatus.open))
            .count(),
        2);
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.anIntEnum(TodoStatus.open))
            .count(),
        2);

    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.anIntEnum.not(TodoStatus.open))
            .count(),
        2);

    // Not Equals
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.anIntEnum.not.equals(TodoStatus.open))
            .count(),
        2);

    // In
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) =>
                f.anIntEnum.isIn([TodoStatus.open, TodoStatus.workInProgress]))
            .count(),
        3);

    // Not In
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.anIntEnum.not
                .isIn([TodoStatus.open, TodoStatus.workInProgress]))
            .count(),
        1);
  });

  test('manager - multiple filters', () async {
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("person"),
        anIntEnum: Value(TodoStatus.open),
        aReal: Value(5.0),
        aDateTime: Value(DateTime.now().add(Duration(days: 1)))));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("person"),
        anIntEnum: Value(TodoStatus.open),
        aDateTime: Value(DateTime.now().add(Duration(days: 2)))));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aText: Value("drink"),
        anIntEnum: Value(TodoStatus.open),
        aReal: Value(3.0),
        aDateTime: Value(DateTime.now().add(Duration(days: 3)))));

    // By default, all filters are AND
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.aText("person"))
            .filter((f) => f.aReal(5.0))
            .count(),
        1);
  });
}
