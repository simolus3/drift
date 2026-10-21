import 'package:drift3_preview/drift.dart';
import 'package:drift_mariadb/drift_mariadb.dart';
import 'package:mysql_client/mysql_client.dart' hide ResultSet;

part 'main.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get name => text();
}

@DriftDatabase(tables: [Users])
final class DriftPostgresDatabase extends _$DriftPostgresDatabase {
  DriftPostgresDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

void main() async {
  final database = DriftPostgresDatabase(
    mariaDbDriftConnection(
      () async => MySQLConnectionPool(
        host: 'localhost',
        port: 3306,
        userName: 'root',
        password: 'password',
        databaseName: 'database',
        maxConnections: 1,
        secure: false,
      ),
    ),
  );

  final user = await database.usersQueries.insertReturning(
    UsersCompanion.insert(name: 'Simon'),
  );
  print(user);

  await database.usersQueries.deleteOne(user);
  await database.close();
}
