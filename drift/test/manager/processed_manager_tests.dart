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
    expect(db.managers.tableWithEveryColumnType.all().count(), completion(3));
    // Test get
    expect(
        db.managers.tableWithEveryColumnType
            .all()
            .get()
            .then((value) => value.length),
        completion(3));
    // Test getSingle with limit
    expect(
        db.managers.tableWithEveryColumnType
            .all()
            .limit(1, offset: 1)
            .getSingle()
            .then((value) => value.id),
        completion(2));
    // Test filtered delete
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.id(RowId(2)))
            .delete(),
        completion(1));

    // Test filtered update
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.id(RowId(1)))
            .update((o) => o(aReal: Value(10.0))),
        completion(1));
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.id(RowId(1)))
            .getSingle()
            .then((value) => value.aReal),
        completion(10.0));
    // Test filtered exists
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.id(RowId(1)))
            .exists(),
        completion(true));

    // Test filtered count
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.id(RowId(1)))
            .count(),
        completion(1));
    // Test delte all
    expect(db.managers.tableWithEveryColumnType.delete(), completion(2));
    // Test exists - false
    expect(
        db.managers.tableWithEveryColumnType
            .filter((f) => f.id(RowId(1)))
            .exists(),
        completion(false));
  });
}
