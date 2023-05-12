import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  test('regression test for #1232', () async {
    // replace with generated table
    final db = TodoDb(testInMemoryDatabase());
    final someTables = {db.todosTable};

    await db.customStatement('create table tbl (x int)');
    await db.customInsert('insert into tbl values(1)');

    Stream<int> watchValue() => db
        .customSelect('select * from tbl', readsFrom: someTables)
        .map((row) => row.read<int>('x'))
        .watchSingle();

    expect(await watchValue().first, 1);
    await Future<void>.delayed(Duration.zero);

    watchValue().listen(null);

    await db.customUpdate('update tbl set x = 2',
        updates: someTables, updateKind: UpdateKind.update);

    expect(await watchValue().first, 2);
  });
}
