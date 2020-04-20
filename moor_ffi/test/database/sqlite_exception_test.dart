import 'dart:io';

import 'package:moor_ffi/database.dart';
import 'package:moor_ffi/src/bindings/constants.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  test('open read-only exception', () async {
    final path =
        join('.dart_tool', 'moor_ffi', 'test', 'read_only_exception.db');
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
    } on SqliteException catch (e) {
      expect(e.extendedResultCode, Errors.SQLITE_CANTOPEN);
      expect(e.toString(), startsWith('SqliteException(14): '));
    }
  });

  test('statement exception', () async {
    // Only testing some common errors...
    final db = Database.memory();

    // Basic syntax error
    try {
      db.execute('DUMMY');
      fail('should fail');
    } on SqliteException catch (e) {
      expect(e.extendedResultCode, Errors.SQLITE_ERROR);
      expect(e.resultCode, Errors.SQLITE_ERROR);
      expect(e.toString(), startsWith('SqliteException(1): '));
    }

    // No table
    try {
      db.execute('SELECT * FROM missing_table');
      fail('should fail');
    } on SqliteException catch (e) {
      expect(e.extendedResultCode, Errors.SQLITE_ERROR);
      expect(e.resultCode, Errors.SQLITE_ERROR);
    }

    // Constraint primary key
    db.execute('CREATE TABLE Test (name TEXT PRIMARY KEY)');
    db.execute("INSERT INTO Test(name) VALUES('test1')");
    try {
      db.execute("INSERT INTO Test(name) VALUES('test1')");
      fail('should fail');
    } on SqliteException catch (e) {
      // SQLITE_CONSTRAINT_PRIMARYKEY (1555)
      expect(e.extendedResultCode, 1555);
      expect(e.resultCode, Errors.SQLITE_CONSTRAINT);
      expect(e.toString(), startsWith('SqliteException(1555): '));
    }

    // Constraint using prepared statement
    db.execute('CREATE TABLE Test2 (id PRIMARY KEY, name TEXT UNIQUE)');
    final prepared = db.prepare('INSERT INTO Test2(name) VALUES(?)');
    prepared.execute(['test2']);
    try {
      prepared.execute(['test2']);
      fail('should fail');
    } on SqliteException catch (e) {
      // SQLITE_CONSTRAINT_UNIQUE (2067)
      expect(e.extendedResultCode, 2067);
      expect(e.resultCode, Errors.SQLITE_CONSTRAINT);
    }
    db.close();
  });

  test('busy exception', () async {
    final path = join('.dart_tool', 'moor_ffi', 'test', 'busy.db');
    // Make sure the path exists
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}
    // but not the db
    try {
      await File(path).delete();
    } catch (_) {}

    final db1 = Database.open(path);
    final db2 = Database.open(path);
    db1.execute('BEGIN EXCLUSIVE TRANSACTION');
    try {
      db2.execute('BEGIN EXCLUSIVE TRANSACTION');
      fail('should fail');
    } on SqliteException catch (e) {
      expect(e.extendedResultCode, Errors.SQLITE_BUSY);
      expect(e.resultCode, Errors.SQLITE_BUSY);
    }
    db1.close();
    db2.close();
  });

  test('invalid format', () async {
    final path = join('.dart_tool', 'moor_ffi', 'test', 'invalid_format.db');
    // Make sure the path exists
    try {
      await Directory(dirname(path)).create(recursive: true);
    } catch (_) {}
    await File(path).writeAsString('not a database file');

    final db = Database.open(path);
    try {
      db.setUserVersion(1);
      fail('should fail');
    } on SqliteException catch (e) {
      expect(e.extendedResultCode, Errors.SQLITE_NOTADB);
      expect(e.resultCode, Errors.SQLITE_NOTADB);
    }
    db.close();
  }, solo: true);
}
