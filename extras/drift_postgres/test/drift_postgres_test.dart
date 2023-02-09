import 'package:drift_postgres/postgres.dart';
import 'package:drift_testcases/tests.dart';
import 'package:postgres/postgres_v3_experimental.dart';

class PgExecutor extends TestExecutor {
  @override
  bool get supportsReturning => true;

  @override
  bool get hackyVariables => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection(PgDatabase(
      endpoint: PgEndpoint(
        host: 'localhost',
        database: 'postgres',
        username: 'postgres',
        password: 'postgres',
      ),
    ));
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
