import 'package:moor/moor.dart';
import 'package:sqljocky5/connection/settings.dart';

import 'mysql.dart';

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@UseMoor(tables: [Users])
class Database extends _$Database {
  Database._(QueryExecutor e) : super(e);

  factory Database() {
    final settings = ConnectionSettings(
      user: 'root',
      password: 'password',
      host: 'localhost',
      port: 3306,
      db: 'example',
    );

    return Database._(MySqlBackend(settings));
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (engine, details) async {
        // we don't have migrations in mysql, so let's run them manually here!
        final migrator = Migrator(this, engine.customStatement);
        // will emit a "IF NOT EXISTS" statement, so its safe to run this
        // on every open
        await migrator.createAllTables();
      },
    );
  }

  Future<void> insertUser(String name) async {
    await into(users).insert(UsersCompanion(name: Value(name)));
  }
}
