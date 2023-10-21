import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart';

part 'postgres.g.dart';

class Users extends Table {
  UuidColumn get id => customType(PgTypes.uuid).withDefault(genRandomUuid())();
  TextColumn get name => text()();
  DateTimeColumn get birthDate => dateTime().nullable()();
}

@DriftDatabase(tables: [Users])
class MyDatabase extends _$MyDatabase {
  MyDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

void main() async {
  final pgDatabase = PgDatabase(
    endpoint: Endpoint(
      host: 'localhost',
      database: 'postgres',
      username: 'postgres',
      password: 'postgres',
    ),
  );

  final driftDatabase = MyDatabase(pgDatabase);

  // Insert a new user
  await driftDatabase.users.insertOne(UsersCompanion.insert(name: 'Simon'));

  // Print all of them
  print(await driftDatabase.users.all().get());

  await driftDatabase.close();
}
