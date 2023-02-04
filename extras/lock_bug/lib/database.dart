import 'package:drift/drift.dart';

part 'database.g.dart';

class Users extends Table {
  /// The user id
  IntColumn get id => integer().autoIncrement()();

  // The user name
  TextColumn get name => text()();

  /// The users birth date
  ///
  /// Mapped from json `born_on`
  DateTimeColumn get birthDate => dateTime()();

  BlobColumn get profilePicture => blob().nullable()();
}

@DriftDatabase(
  tables: [Users],
)
class Database extends _$Database {
  /// We make the schema version configurable to test migrations
  @override
  final int schemaVersion;

  Database(super.connection, {this.schemaVersion = 2}) : super.connect();

  Database.executor(QueryExecutor db) : this(DatabaseConnection(db));

  /// It will be set in the onUpgrade callback. Null if no migration occurred
  int? schemaVersionChangedFrom;

  /// It will be set in the onUpgrade callback. Null if no migration occurred
  int? schemaVersionChangedTo;

  MigrationStrategy? overrideMigration;

  @override
  MigrationStrategy get migration {
    return overrideMigration ??
        MigrationStrategy(
          onCreate: (m) async {
            await m.createTable(users);
          },
        );
  }
}
