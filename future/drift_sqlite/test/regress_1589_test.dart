@TestOn('vm')
library;

import 'dart:io';

import 'package:drift3/drift.dart';
import 'package:drift_sqlite/native.dart';
import 'package:drift_sqlite/src/connection/connection.dart';
import 'package:drift_sqlite/src/dialect/dialect.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  group('a failing commit does not block the whole database', () {
    Future<void> testWith(DriftConnection executor) async {
      final db = _Database(executor);
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
            [
              db.mapValue(BuiltinDriftType.text, 'a'),
              db.mapValue(BuiltinDriftType.int, 100),
            ],
          );
        }),
        throwsA(anyOf(isA<SqliteException>())),
      );

      expect(
        db.customSelect('SELECT * FROM todo_items').get(),
        completion(isEmpty),
      );
    }

    test('sync client', () async {
      await testWith(
        DriftConnection(
          dialect: const SqliteDialect(),
          openConnection: () async => SqliteConnection(sqlite3.openInMemory()),
        ),
      );
    });

    test('pool', () async {
      final file = File(d.path('test.db'));
      await testWith(sqliteConnectionPool(file: file));
    });
  });
}

final class _Database extends GeneratedDatabase {
  _Database(super.executor);

  @override
  int get schemaVersion => 1;
  @override
  DatabaseSchema get schema => .empty;
}
