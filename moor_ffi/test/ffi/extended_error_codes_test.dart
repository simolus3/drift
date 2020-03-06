import 'package:moor_ffi/database.dart';
import 'package:test/test.dart';

void main() {
  Database database;

  setUp(() => database = Database.memory());

  tearDown(() => database.close());

  test('violating constraint throws exception with extended error code', () {
    database.execute('CREATE TABLE tbl(a INTEGER NOT NULL)');

    final statement = database.prepare('INSERT INTO tbl DEFAULT VALUES');

    expect(
      statement.execute,
      throwsA(
        predicate(
          (e) => e is SqliteException && e.explanation.endsWith(' (code 1299)'),
        ),
      ),
    );
  });
}
