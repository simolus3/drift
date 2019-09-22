import 'package:test/test.dart';

import '../runners.dart';

void main(TestedDatabase db) {
  test('insert statements report their id', () async {
    final opened = await db.openMemory();
    await opened
        .execute('CREATE TABLE tbl(a INTEGER PRIMARY KEY AUTOINCREMENT)');

    for (var i = 0; i < 5; i++) {
      await opened.execute('INSERT INTO tbl DEFAULT VALUES');
      expect(await opened.getLastInsertId(), i + 1);
    }

    await opened.close();
  });
}
