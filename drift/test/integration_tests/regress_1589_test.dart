@TestOn('vm')
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  test('a failing commit does not block the whole database', () async {
    final db = _Database(NativeDatabase.memory());
    addTearDown(db.close);

    await db.customStatement('''
CREATE TABLE IF NOT EXISTS todo_items (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL, content TEXT NULL,
  category_id INTEGER NOT NULL
    REFERENCES todo_categories (id) DEFERRABLE INITIALLY DEFERRED,
  generated_text TEXT NULL
    GENERATED ALWAYS AS (title || ' (' || content || ')') VIRTUAL
);
''');
    await db.customStatement('''
CREATE TABLE IF NOT EXISTS todo_categories (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
);
''');
    await db.customStatement('PRAGMA foreign_keys = ON;');

    await expectLater(
      db.transaction(() async {
        // Thanks to the deferrable clause, this statement will only cause a
        // failing COMMIT.
        await db.customStatement(
            'INSERT INTO todo_items (title, category_id) VALUES (?, ?);',
            ['a', 100]);
      }),
      throwsA(isA<SqliteException>()),
    );

    expect(
        db.customSelect('SELECT * FROM todo_items').get(), completion(isEmpty));
  });
}

class _Database extends GeneratedDatabase {
  _Database(QueryExecutor executor)
      : super(SqlTypeSystem.defaultInstance, executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const Iterable.empty();

  @override
  int get schemaVersion => 1;
}
