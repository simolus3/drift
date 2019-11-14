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
}
