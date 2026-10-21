import 'package:drift_mariadb/drift_mariadb.dart';
import 'package:drift3_testcases/tests.dart';
import 'package:mysql_client/mysql_client.dart';

class MariaDbExecutor extends TestExecutor {
  @override
  bool get supportsReturning => true;

  @override
  bool get supportsNestedTransactions => true;

  @override
  DriftConnection createConnection() {
    final pool = MySQLConnectionPool(
      host: 'localhost',
      port: 3306,
      userName: 'root',
      password: 'password',
      databaseName: 'database',
      maxConnections: 1,
      secure: false,
    );

    return mariaDbDriftConnection(() async => pool);
  }

  @override
  Future clearDatabaseAndClose(Database db) async {
    await db.customStatement('DROP DATABASE `database`;');
    await db.customStatement('CREATE DATABASE `database`;');

    await db.close();
  }

  @override
  Future<void> deleteData() async {}
}

void main() {
  runAllTests(MariaDbExecutor());
}
