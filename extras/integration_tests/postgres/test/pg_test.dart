import 'package:drift/postgres.dart';
import 'package:tests/tests.dart';

class PgExecutor extends TestExecutor {
  @override
  bool get supportsReturning => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.fromExecutor(PgDatabase.open(
        'localhost', 5432, 'postgres',
        username: 'postgres', password: 'postgres'));
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
  Future deleteData() async {}
}

void main() {
  runAllTests(PgExecutor());
}
