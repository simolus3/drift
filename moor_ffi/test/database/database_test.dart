import 'package:moor_ffi/database.dart';
import 'package:test/test.dart';

void main() {
  test("database can't be used after close", () {
    final db = Database.memory();
    db.execute('SELECT 1');

    db.close();

    expect(() => db.execute('SELECT 1'), throwsA(anything));
  });

  test('closing multiple times works', () {
    final db = Database.memory();
    db.execute('SELECT 1');

    db.close();
    db.close(); // shouldn't throw or crash
  });
}
