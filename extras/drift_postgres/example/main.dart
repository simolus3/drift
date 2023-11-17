import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;
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
    endpoint: pg.Endpoint(
      host: 'localhost',
      database: 'postgres',
      username: 'postgres',
      password: 'postgres',
    ),
    settings: pg.ConnectionSettings(
      // If you expect to talk to a Postgres database over a public connection,
      // please use SslMode.verifyFull instead.
      sslMode: pg.SslMode.disable,
    ),
    logStatements: true,
  ));

  final user = await database.users.insertReturning(
      UsersCompanion.insert(name: 'Simon', id: Value(Uuid().v4obj())));
  print(user);

  await database.close();
}
