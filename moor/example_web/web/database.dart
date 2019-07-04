import 'package:moor/moor.dart';

part 'database.g.dart';

@DataClassName('TodoEntry')
class TodoEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get content => text()();
  DateTimeColumn get creationDate =>
      dateTime().withDefault(currentDateAndTime)();
}

@UseMoor(tables: [TodoEntries])
class Database extends _$Database {
  Database(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  Stream<List<TodoEntry>> watchEntries() {
    return select(todoEntries).watch();
  }

  Future<int> insert(String text) {
    return into(todoEntries).insert(TodoEntriesCompanion(content: Value(text)));
  }
}
