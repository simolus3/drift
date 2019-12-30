import 'package:moor_ffi/database.dart';
import 'package:test/test.dart';

void main() {
  test('insert statements report their id', () {
    final opened = Database.memory();
    opened.execute('CREATE TABLE tbl(a INTEGER PRIMARY KEY AUTOINCREMENT)');

    for (var i = 0; i < 5; i++) {
      opened.execute('INSERT INTO tbl DEFAULT VALUES');
      expect(opened.getLastInsertId(), i + 1);
    }

    opened.close();
  });
}
