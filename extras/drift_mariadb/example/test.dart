import 'package:drift/backends.dart';
import 'package:drift/src/runtime/query_builder/query_builder.dart';
import 'package:drift_mariadb/drift_mariadb.dart';
import 'package:mysql_client/mysql_client.dart';

void main() async {
  final mariadb = MariaDBDatabase(
    pool: MySQLConnectionPool(
      host: 'localhost',
      port: 3306,
      userName: 'root',
      password: 'password',
      databaseName: 'database',
      maxConnections: 1,
      secure: false,
    ),
    logStatements: true,
  );

  await mariadb.ensureOpen(_NullUser());

  final rows = await mariadb.runSelect(r'SELECT (?)', [true]);
  final row = rows.single;
  print(row);
  print(row.values.map((e) => e.runtimeType).toList());
}

class _NullUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}

  @override
  int get schemaVersion => 1;
}
