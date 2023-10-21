import 'package:drift_postgres/drift_postgres.dart';
import 'package:drift_testcases/tests.dart';
import 'package:postgres/postgres.dart' as pg;

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
      sessionSettings: pg.SessionSettings(sslMode: pg.SslMode.disable),
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
}
