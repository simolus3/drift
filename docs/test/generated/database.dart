import 'package:drift/drift.dart';

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt =>
      dateTime().nullable().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Users])
class Database extends _$Database {
  Database.connect(DatabaseConnection c) : super(c);

  @override
  int get schemaVersion => 1;

  @override
  DriftDatabaseOptions options = DriftDatabaseOptions();
}
