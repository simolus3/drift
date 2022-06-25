@TestOn('browser')
import 'dart:html';

import 'package:drift/drift.dart';
import 'package:drift/web.dart';
import 'package:drift_testcases/database/database.dart';
import 'package:drift_testcases/suite/suite.dart';
import 'package:test/test.dart';

class WebExecutor extends TestExecutor {
  final String name = 'db';

  @override
  bool get supportsReturning => true;

  @override
  bool get supportsNestedTransactions => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.fromExecutor(WebDatabase(name));
  }

  @override
  Future deleteData() {
    window.localStorage.clear();
    return Future.value();
  }
}

class WebExecutorIndexedDb extends TestExecutor {
  @override
  bool get supportsReturning => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.fromExecutor(
      WebDatabase.withStorage(DriftWebStorage.indexedDb('foo')),
    );
  }

  @override
  Future deleteData() async {
    await window.indexedDB?.deleteDatabase('moor_databases');
  }
}

void main() {
  group('using local storage', () {
    runAllTests(WebExecutor());
  });

  group('using IndexedDb', () {
    runAllTests(WebExecutorIndexedDb());
  });

  test('can run multiple statements in one call', () async {
    final db = Database(DatabaseConnection.fromExecutor(
        WebDatabase.withStorage(DriftWebStorage.volatile())));
    addTearDown(db.close);

    await db.customStatement(
        'CREATE TABLE x1 (a INTEGER); INSERT INTO x1 VALUES (1);');
    final results = await db.customSelect('SELECT * FROM x1;').get();
    expect(results.length, 1);
  });
}
