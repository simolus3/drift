import 'package:sally_flutter/sally_flutter.dart';

part 'database.g.dart';

@DataClassName('TodoEntry')
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 4, max: 16).nullable()();

  TextColumn get content => text()();

  DateTimeColumn get targetDate => dateTime().nullable()();

  IntColumn get category => integer().nullable()();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get description => text().named('desc')();
}

@UseSally(tables: [Todos, Categories])
class Database extends _$Database {
  Database()
      : super(FlutterQueryExecutor.inDatabaseFolder(
            path: 'db.sqlite', logStatements: true));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) {
      return m.createAllTables();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        await m.addColumn(todos, todos.targetDate);
      }
    }
  );

  Stream<List<TodoEntry>> allEntries() {
    return select(todos).watch();
  }

  Future addEntry(TodoEntry entry) {
    return into(todos).insert(entry);
  }

  Future deleteEntry(TodoEntry entry) {
    return (delete(todos)..where((t) => t.id.equals(entry.id))).go();
  }
}
