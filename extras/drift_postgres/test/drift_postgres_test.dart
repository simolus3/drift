import 'package:drift_postgres/drift_postgres.dart';
import 'package:drift_testcases/tests.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';

class PgExecutor extends TestExecutor {
  @override
  bool get supportsReturning => true;

  @override
  bool get supportsNestedTransactions => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection(PgDatabase(
      endpoint: pg.Endpoint(
        host: 'localhost',
        database: 'postgres',
        username: 'postgres',
        password: 'postgres',
      ),
      settings: pg.ConnectionSettings(sslMode: pg.SslMode.disable),
    ));
  }

  @override
  Future clearDatabaseAndClose(GeneratedDatabase db) async {
    await db.customStatement('DROP SCHEMA public CASCADE;');
    await db.customStatement('CREATE SCHEMA public;');
    await db.customStatement('GRANT ALL ON SCHEMA public TO postgres;');
    await db.customStatement('GRANT ALL ON SCHEMA public TO public;');
    await db.close();
  }

  @override
  Future<void> deleteData() async {}
}

void main() {
  runAllTests(PgExecutor());

  // Regression for https://github.com/simolus3/drift/issues/2981
  test('bind null to nullable column', () async {
    final executor = PgExecutor();
    final db = Database(executor.createConnection());

    await db.customStatement('''
CREATE TABLE mytable (
  id INTEGER PRIMARY KEY NOT NULL,
  value INTEGER
);
''');

    // Provide null to a nullable column
    await db.customInsert(
      r'INSERT INTO mytable (id, value) VALUES (1, $1);',
      variables: [Variable(null)],
    );

    await executor.clearDatabaseAndClose(db);
  });
}
