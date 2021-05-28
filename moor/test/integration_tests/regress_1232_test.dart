@TestOn('vm')
import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';

void main() {
  test('regression test for #1232', () async {
    // replace with generated table
    final db = TodoDb(VmDatabase.memory());
    final someTables = {db.todosTable};

    await db.customStatement('create table tbl (x int)');
    await db.customInsert('insert into tbl values(1)');

    Stream<int> watchValue() => db
        .customSelect('select * from tbl', readsFrom: someTables)
        .map((row) => row.read<int>('x'))
        .watchSingle();

    expect(await watchValue().first, 1);
    await Future.delayed(Duration.zero);

    watchValue().listen(null);

    await db.customUpdate('update tbl set x = 2',
        updates: someTables, updateKind: UpdateKind.update);

    expect(await watchValue().first, 2);
  });
}
