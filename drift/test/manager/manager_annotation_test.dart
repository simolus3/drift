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

  test('manager - generic annotation', () async {
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aBlob: Value(Uint8List(0)),
        aBool: Value(true),
        anInt: Value(5),
        anInt64: Value(BigInt.from(5)),
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aReal: Value(3.0),
        aDateTime: Value(DateTime.now().add(Duration(days: 3)))));

    final aTextAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aText);
    final aRealAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aReal);
    final anIntEnumAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anIntEnum);
    final anIntEnumWithConverterAnnotation = db
        .managers.tableWithEveryColumnType
        .annotationWithConverter((a) => a.anIntEnum);
    final aDateTimeAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aDateTime);
    final aBlobAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aBlob);
    final aBoolAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aBool);
    final anIntAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anInt);
    final anInt64Annotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anInt64);
    final (_, refs) =
        await db.managers.tableWithEveryColumnType.withAnnotations([
      aTextAnnotation,
      aRealAnnotation,
      anIntEnumAnnotation,
      aDateTimeAnnotation,
      aBlobAnnotation,
      aBoolAnnotation,
      anIntAnnotation,
      anInt64Annotation,
      anIntEnumWithConverterAnnotation,
    ]).getSingle();
    expect(aTextAnnotation.read(refs), "Get that math homework done");
    expect(aRealAnnotation.read(refs), 3.0);
    expect(anIntEnumAnnotation.read(refs), TodoStatus.open.index);
    expect(anIntEnumWithConverterAnnotation.read(refs), TodoStatus.open);
    expect(aDateTimeAnnotation.read(refs), isA<DateTime>());
    expect(aBlobAnnotation.read(refs), isA<Uint8List>());
    expect(aBoolAnnotation.read(refs), true);
    expect(anIntAnnotation.read(refs), 5);
    expect(anInt64Annotation.read(refs), BigInt.from(5));
  });

  test('manager - generic nullable annotation', () async {
    await db.managers.tableWithEveryColumnType.create((o) => o());

    final aTextAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aText);
    final aRealAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aReal);
    final anIntEnumAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anIntEnum);
    final anIntEnumWithConverterAnnotation = db
        .managers.tableWithEveryColumnType
        .annotationWithConverter((a) => a.anIntEnum);
    final aDateTimeAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aDateTime);
    final aBlobAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aBlob);
    final aBoolAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aBool);
    final anIntAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anInt);
    final anInt64Annotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anInt64);
    final (_, refs) =
        await db.managers.tableWithEveryColumnType.withAnnotations([
      aTextAnnotation,
      aRealAnnotation,
      anIntEnumAnnotation,
      aDateTimeAnnotation,
      aBlobAnnotation,
      aBoolAnnotation,
      anIntAnnotation,
      anInt64Annotation,
      anIntEnumWithConverterAnnotation,
    ]).getSingle();
    expect(aTextAnnotation.read(refs), null);
    expect(aRealAnnotation.read(refs), null);
    expect(anIntEnumAnnotation.read(refs), null);
    expect(anIntEnumWithConverterAnnotation.read(refs), null);
    expect(aDateTimeAnnotation.read(refs), null);
    expect(aBlobAnnotation.read(refs), null);
    expect(aBoolAnnotation.read(refs), null);
    expect(anIntAnnotation.read(refs), null);
    expect(anInt64Annotation.read(refs), null);
  });

  test('manager - generic filter annotation', () async {
    final in3Days = DateTime.now().add(Duration(days: 3));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aBlob: Value(Uint8List(0)),
        aBool: Value(true),
        anInt: Value(5),
        anInt64: Value(BigInt.from(5)),
        aText: Value("Get that math homework done"),
        anIntEnum: Value(TodoStatus.open),
        aReal: Value(3.0),
        aDateTime: Value(in3Days)));
    await db.managers.tableWithEveryColumnType.create((o) => o(
        aBlob: Value(Uint8List(50)),
        aBool: Value(false),
        anInt: Value(1),
        anInt64: Value(BigInt.from(10)),
        aText: Value("Do Nothing"),
        anIntEnum: Value(TodoStatus.done),
        aReal: Value(2),
        aDateTime: Value(DateTime.now().add(Duration(days: 2)))));

    final aTextAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aText);
    final aRealAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aReal);
    final anIntEnumAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anIntEnum);
    final anIntEnumWithConverterAnnotation = db
        .managers.tableWithEveryColumnType
        .annotationWithConverter((a) => a.anIntEnum);
    final aDateTimeAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aDateTime);
    final aBlobAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aBlob);
    final aBoolAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.aBool);
    final anIntAnnotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anInt);
    final anInt64Annotation =
        db.managers.tableWithEveryColumnType.annotation((a) => a.anInt64);

    // If any of these filters dont work, there will be more than one row returned, which will cause an exception
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([aTextAnnotation])
            .filter(
                (f) => aTextAnnotation.filter("Get that math homework done"))
            .getSingle()
            .then((value) => aTextAnnotation.read(value.$2)),
        "Get that math homework done");
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([aRealAnnotation])
            .filter((f) => aRealAnnotation.filter(3.0))
            .getSingle()
            .then((value) => aRealAnnotation.read(value.$2)),
        3.0);
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([anIntEnumAnnotation])
            .filter((f) => anIntEnumAnnotation.filter(TodoStatus.open.index))
            .getSingle()
            .then((value) => anIntEnumAnnotation.read(value.$2)),
        TodoStatus.open.index);
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([anIntEnumWithConverterAnnotation])
            .filter(
                (f) => anIntEnumWithConverterAnnotation.filter(TodoStatus.open))
            .getSingle()
            .then((value) => anIntEnumWithConverterAnnotation.read(value.$2)),
        TodoStatus.open);
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([aDateTimeAnnotation])
            .filter((f) => aDateTimeAnnotation.filter(in3Days))
            .getSingle()
            // Default DB only has second level precision
            .then((value) =>
                aDateTimeAnnotation.read(value.$2)!.millisecondsSinceEpoch ~/
                1000),
        in3Days.millisecondsSinceEpoch ~/ 1000);
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([aBlobAnnotation])
            .filter((f) => aBlobAnnotation.filter(Uint8List(0)))
            .getSingle()
            .then((value) => aBlobAnnotation.read(value.$2)),
        Uint8List(0));
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([aBoolAnnotation])
            .filter((f) => aBoolAnnotation.filter(true))
            .getSingle()
            .then((value) => aBoolAnnotation.read(value.$2)),
        true);
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([anIntAnnotation])
            .filter((f) => anIntAnnotation.filter(5))
            .getSingle()
            .then((value) => anIntAnnotation.read(value.$2)),
        5);
    expect(
        await db.managers.tableWithEveryColumnType
            .withAnnotations([anInt64Annotation])
            .filter((f) => anInt64Annotation.filter(BigInt.from(5)))
            .getSingle()
            .then((value) => anInt64Annotation.read(value.$2)),
        BigInt.from(5));
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

  test('can use shorthand filter for nulls', () async {
    final row = await db.todosTable.insertReturning(
        TodosTableCompanion.insert(content: 'my test content'));

    final query =
        await db.managers.todosTable.filter((f) => f.targetDate(null)).get();
    expect(query, [row]);
  });
}
