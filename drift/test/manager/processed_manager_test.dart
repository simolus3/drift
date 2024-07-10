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

  test('processed manager', () async {
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
    // Test count
    expect(await db.managers.tableWithEveryColumnType.count(), 3);
    // Test get
    expect(await db.managers.tableWithEveryColumnType.get(), hasLength(3));
    // Test getSingle with limit
    expect(
        await db.managers.tableWithEveryColumnType
            .limit(1, offset: 1)
            .getSingle()
            .then((value) => value.id),
        2);
    // Test filtered delete
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.id(RowId(2)))
            .delete(),
        completion(1));

    // Test filtered update
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.id(RowId(1)))
            .update((o) => o(aReal: Value(10.0))),
        1);
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.id(RowId(1)))
            .getSingle()
            .then((value) => value.aReal),
        10.0);
    // Test filtered exists
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.id(RowId(1)))
            .exists(),
        true);

    // Test filtered count
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.id(RowId(1)))
            .count(),
        1);
    // Test delete all
    expect(await db.managers.tableWithEveryColumnType.delete(), 2);
    // Test exists - false
    expect(
        await db.managers.tableWithEveryColumnType
            .filter((f) => f.id(RowId(1)))
            .exists(),
        false);
  });
}
