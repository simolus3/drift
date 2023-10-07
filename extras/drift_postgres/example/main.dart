import 'package:drift/drift.dart';
import 'package:drift_postgres/postgres.dart';
import 'package:postgres/postgres_v3_experimental.dart';
import 'package:uuid/uuid.dart';

part 'main.g.dart';

class Users extends Table {
  UuidColumn get id => customType(PgTypes.uuid).withDefault(genRandomUuid())();
  TextColumn get name => text()();
}

@DriftDatabase(tables: [Users])
class DriftPostgresDatabase extends _$DriftPostgresDatabase {
  DriftPostgresDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

void main() async {
  final database = DriftPostgresDatabase(PgDatabase(
    endpoint: PgEndpoint(
      host: 'localhost',
      database: 'postgres',
      username: 'postgres',
      password: 'postgres',
    ),
    logStatements: true,
  ));

  final user = await database.users.insertReturning(
      UsersCompanion.insert(name: 'Simon', id: Value(Uuid().v4obj())));
  print(user);

  await database.close();
}
