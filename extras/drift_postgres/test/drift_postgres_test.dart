import 'package:drift_postgres/postgres.dart';
import 'package:drift_testcases/tests.dart';
import 'package:postgres/postgres.dart';

class PgExecutor extends TestExecutor {
  @override
  bool get supportsReturning => true;

  @override
  bool get supportsNestedTransactions => true;

  @override
  DatabaseConnection createConnection() {
    final pgConnection = PostgreSQLConnection('localhost', 5432, 'postgres',
        username: 'postgres', password: 'postgres');
    return DatabaseConnection(PgDatabase(pgConnection));
  }

  @override
  Future clearDatabaseAndClose(Database db) async {
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
}
