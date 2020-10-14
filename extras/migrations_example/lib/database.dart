import 'package:moor/moor.dart';

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()(); // added in schema version 2
}

@UseMoor(tables: [Users])
class Database extends _$Database {
  @override
  final int schemaVersion;

  Database(this.schemaVersion, DatabaseConnection connection)
      : super.connect(connection);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, before, now) async {
        await m.addColumn(users, users.name);
      },
    );
  }
}
