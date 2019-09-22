import 'package:test/test.dart';

import '../runners.dart';

void main(TestedDatabase db) {
  test('select statements return expected value', () async {
    final opened = await db.openMemory();

    final prepared = await opened.prepare('SELECT ?');

    final result1 = await prepared.select([1]);
    expect(result1.columnNames, ['?']);
    expect(result1.single.columnAt(0), 1);

    final result2 = await prepared.select([2]);
    expect(result2.columnNames, ['?']);
    expect(result2.single.columnAt(0), 2);

    await opened.close();
  });
}
