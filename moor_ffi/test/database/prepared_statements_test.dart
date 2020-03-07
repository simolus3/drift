import 'dart:typed_data';

import 'package:moor_ffi/database.dart';
import 'package:test/test.dart';

void main() {
  test('prepared statements can be used multiple times', () {
    final opened = Database.memory();
    opened.execute('CREATE TABLE tbl (a TEXT);');

    final stmt = opened.prepare('INSERT INTO tbl(a) VALUES(?)');
    stmt.execute(['a']);
    stmt.execute(['b']);
    stmt.close();

    final select = opened.prepare('SELECT * FROM tbl ORDER BY a');
    final result = select.select();

    expect(result, hasLength(2));
    expect(result.map((row) => row['a']), ['a', 'b']);

    select.close();

    opened.close();
  });

  test('prepared statements cannot be used after close', () {
    final opened = Database.memory();

    final stmt = opened.prepare('SELECT ?');
    stmt.close();

    expect(stmt.select, throwsA(anything));

    opened.close();
  });

  test('prepared statements cannot be used after db is closed', () {
    final opened = Database.memory();
    final stmt = opened.prepare('SELECT 1');
    opened.close();

    expect(stmt.select, throwsA(anything));
  });

  Uint8List _insertBlob(Uint8List value) {
    final opened = Database.memory();
    opened.execute('CREATE TABLE tbl (x BLOB);');

    final insert = opened.prepare('INSERT INTO tbl VALUES (?)');
    insert.execute([value]);
    insert.close();

    final select = opened.prepare('SELECT * FROM tbl');
    final result = select.select().single;

    opened.close();
    return result['x'] as Uint8List;
  }

  test('can bind empty blob in prepared statements', () {
    expect(_insertBlob(Uint8List(0)), isEmpty);
  });

  test('can bind null blob in prepared statements', () {
    expect(_insertBlob(null), isNull);
  });

  test('can bind and read non-empty blob', () {
    const bytes = [1, 2, 3];
    expect(_insertBlob(Uint8List.fromList(bytes)), bytes);
  });

  test('throws when sql statement has an error', () {
    final db = Database.memory();
    db.execute('CREATE TABLE foo (id INTEGER CHECK (id > 10));');

    final stmt = db.prepare('INSERT INTO foo VALUES (9)');

    expect(
      stmt.execute,
      throwsA(const TypeMatcher<SqliteException>()
          .having((e) => e.message, 'message', contains('foo'))),
    );

    db.close();
  });
}
