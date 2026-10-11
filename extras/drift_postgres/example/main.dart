import 'package:drift3_preview/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:uuid/uuid.dart';

part 'main.g.dart';

class Users extends Table {
  UuidColumn get id => col(PgTypes.uuid).withDefault(genRandomUuid());
  TextColumn get name => text();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DriftDatabase(tables: [Users])
final class DriftPostgresDatabase extends _$DriftPostgresDatabase {
  DriftPostgresDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

void main() async {
  final connection = DriftConnection(
    dialect: PostgresDialect.new,
    openConnection: (_) async {
      final endpoint = pg.Endpoint(
        host: 'localhost',
        database: 'postgres',
        username: 'postgres',
        password: 'postgres',
      );
      final connection = await PostgresSession.open(
        endpoint,
        settings: pg.ConnectionSettings(sslMode: pg.SslMode.disable),
      );
      return connection;
    },
  );

  final database = DriftPostgresDatabase(connection);

  final user = await database.usersQueries.insertReturning(
    UsersCompanion.insert(name: 'Simon', id: Value(Uuid().v4obj())),
  );
  print(user);

  await database.usersQueries.deleteOne(user);

  await database.close();
}
