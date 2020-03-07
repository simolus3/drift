import 'package:moor_ffi/database.dart';
import 'package:test/test.dart';

void main() {
  test("database can't be used after close", () {
    final db = Database.memory();
    db.execute('SELECT 1');

    db.close();

    expect(() => db.execute('SELECT 1'), throwsA(anything));
  });

  test('getUpdatedRows', () {
    final db = Database.memory();

    db
      ..execute('CREATE TABLE foo (bar INT);')
      ..execute('INSERT INTO foo VALUES (3);');

    expect(db.getUpdatedRows(), 1);
  });

  test('closing multiple times works', () {
    final db = Database.memory();
    db.execute('SELECT 1');

    db.close();
    db.close(); // shouldn't throw or crash
  });

  test('throws exception on an invalid statement', () {
    final db = Database.memory();
    db.execute('CREATE TABLE foo (bar INTEGER CHECK (bar > 10));');

    expect(
      () => db.execute('INSERT INTO foo VALUES (3);'),
      throwsA(const TypeMatcher<SqliteException>().having(
          (e) => e.message, 'message', contains('CHECK constraint failed'))),
    );

    db.close();
  });

  test('throws when preparing an invalid statement', () {
    final db = Database.memory();

    expect(
      () => db.prepare('INSERT INTO foo VALUES (3);'),
      throwsA(const TypeMatcher<SqliteException>()
          .having((e) => e.message, 'message', contains('no such table'))),
    );

    db.close();
  });
}
