import 'dart:io';

import 'package:encrypted_drift/encrypted_drift.dart';
import 'package:drift_testcases/tests.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' hide Database;

class SqfliteExecutor extends TestExecutor {
  // Nested transactions are not yet
  @override
  bool get supportsNestedTransactions => false;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection(
      EncryptedExecutor.inDatabaseFolder(
        password: 'default_password',
        path: 'app.db',
        singleInstance: false,
      ),
    );
  }

  @override
  Future deleteData() async {
    final folder = await getDatabasesPath();
    final file = File(join(folder, 'app.db'));

    if (await file.exists()) {
      await file.delete();
    }
  }
}

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  runAllTests(SqfliteExecutor());

  test('can rollback transactions', () async {
    final executor = EncryptedExecutor(password: 'testpw', path: ':memory:');
    final database = EmptyDb(executor);
    addTearDown(database.close);

    final expectedException = Exception('oops');

    try {
      await database
          .customSelect('select 1')
          .getSingle(); // ensure database is open/created

      await database.transaction(() async {
        await database.customSelect('select 1').watchSingle().first;
        throw expectedException;
      });
    } catch (e) {
      expect(e, expectedException);
    } finally {
      await database.customSelect('select 1').getSingle().timeout(
            const Duration(milliseconds: 500),
            onTimeout: () => fail('deadlock?'),
          );
    }
  });

  test('handles failing commits', () async {
    final executor = EncryptedExecutor(password: 'testpw', path: ':memory:');
    final database = EmptyDb(executor);
    addTearDown(database.close);

    await database.customStatement('PRAGMA foreign_keys = ON;');
    await database.customStatement('CREATE TABLE x (foo INTEGER PRIMARY KEY);');
    await database.customStatement('CREATE TABLE y (foo INTEGER PRIMARY KEY '
        'REFERENCES x (foo) DEFERRABLE INITIALLY DEFERRED);');

    await expectLater(
      database.transaction(() async {
        await database.customStatement('INSERT INTO y VALUES (2);');
      }),
      throwsA(isA<CouldNotRollBackException>()),
    );
  });

  test('encrypts database', () async {
    final executor1 = EncryptedExecutor.inDatabaseFolder(
        password: 'testpw', path: 'encryption.db', logStatements: true);
    await executor1.ensureOpen(EmptyDb(executor1));
    await executor1.close();
  });
}

class EmptyDb extends GeneratedDatabase {
  EmptyDb(QueryExecutor q) : super(q);
  @override
  final List<TableInfo> allTables = const [];
  @override
  final schemaVersion = 1;
}
