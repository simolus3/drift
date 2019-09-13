import 'package:moor/moor_web.dart';

part 'database.g.dart';

const int _doneEntriesCount = 20;

@DataClassName('Entry')
class TodoEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get content => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
}

@UseMoor(tables: [
  TodoEntries
], queries: {
  'hiddenEntryCount': 'SELECT COUNT(*) - $_doneEntriesCount AS entries '
      'FROM todo_entries WHERE done'
})
class Database extends _$Database {
  Database() : super(WebDatabase('app', logStatements: true));

  @override
  final int schemaVersion = 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async => await m.createAllTables(),
      beforeOpen: (details) async {
        if (details.wasCreated) {
          // populate default data
          await createTodoEntry(
            'A simple todo list using moor web',
          );
          await createTodoEntry(
            'It even supports prepopulated data!',
          );
        }
      },
    );
  }

  Stream<List<Entry>> incompleteEntries() {
    return (select(todoEntries)..where((e) => not(e.done))).watch();
  }

  Stream<List<Entry>> newestDoneEntries() {
    return (select(todoEntries)
          ..where((e) => e.done)
          ..orderBy(
              [(e) => OrderingTerm(expression: e.id, mode: OrderingMode.desc)])
          ..limit(_doneEntriesCount))
        .watch();
  }

  Future createTodoEntry(String desc) {
    return into(todoEntries).insert(TodoEntriesCompanion(content: Value(desc)));
  }

  Future setCompleted(Entry entry, bool done) {
    return update(todoEntries).replace(entry.copyWith(done: done));
  }
}
