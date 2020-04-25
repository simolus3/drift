import 'dart:io';

import 'package:moor_ffi/database.dart';
import 'package:path/path.dart';
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

  test('open read-only', () async {
    final path = join('.dart_tool', 'moor_ffi', 'test', 'read_only.db');
    // Make sure the path exists
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}
    // but not the db
    try {
      await File(path).delete();
    } catch (_) {}

    // Opening a non-existent database should fail
    try {
      Database.open(path, readOnly: true);
      fail('should fail');
    } on SqliteException catch (_) {}

    // Open in read-write mode to create the database
    var db = Database.open(path);
    // Change the user version to test read-write access
    db.setUserVersion(1);
    db.close();

    // Open in read-only
    db = Database.open(path, readOnly: true);
    // Change the user version to test read-only mode
    try {
      db.setUserVersion(2);
      fail('should fail');
    } on SqliteException catch (_) {}
    // Check that it has not changed
    expect(db.userVersion(), 1);

    db.close();
  });
}
