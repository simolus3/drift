@TestOn('vm')
import 'package:moor/moor.dart';
import 'package:moor/ffi.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';

void main() {
  late TodoDb db;

  setUp(() {
    db = TodoDb(VmDatabase.memory());
  });

  test('insertOnConflictUpdate', () async {
    await db.into(db.categories).insert(
        CategoriesCompanion.insert(description: 'original description'));

    var row = await db.select(db.categories).getSingle();

    await db.into(db.categories).insertOnConflictUpdate(CategoriesCompanion(
        id: Value(row.id), description: const Value('changed description')));

    row = await db.select(db.categories).getSingle();
    expect(row.description, 'changed description');
  });
}
