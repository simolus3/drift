import 'package:test/test.dart';

import '../runners.dart';

void main(TestedDatabase db) {
  test('prepared statements can be used multiple times', () async {
    final opened = await db.openMemory();
    await opened.execute('CREATE TABLE tbl (a TEXT);');

    final stmt = await opened.prepare('INSERT INTO tbl(a) VALUES(?)');
    await stmt.execute(['a']);
    await stmt.execute(['b']);
    await stmt.close();

    final select = await opened.prepare('SELECT * FROM tbl ORDER BY a');
    final result = await select.select();

    expect(result, hasLength(2));
    expect(result.map((row) => row['a']), ['a', 'b']);

    await select.close();

    await opened.close();
  });

  test('prepared statements cannot be used after close', () async {
    final opened = await db.openMemory();

    final stmt = await opened.prepare('SELECT ?');
    await stmt.close();

    expect(stmt.select, throwsA(anything));

    await opened.close();
  });

  test('prepared statements cannot be used after db is closed', () async {
    final opened = await db.openMemory();
    final stmt = await opened.prepare('SELECT 1');
    await opened.close();

    expect(stmt.select, throwsA(anything));
  });
}
