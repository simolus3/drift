import 'package:sally/sally.dart';

part 'todos.g.dart';

@DataClassName('TodoEntry')
class TodosTable extends Table {
  @override
  String get tableName => 'todos';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 4, max: 16).nullable()();
  TextColumn get content => text()();

  IntColumn get category => integer().nullable()();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 6, max: 32)();
  BoolColumn get isAwesome => boolean()();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text().named('desc')();
}

@UseSally(tables: [TodosTable, Categories, Users])
class TodoDb extends _$TodoDb {
  TodoDb(QueryExecutor e) : super(e);

  @override
  MigrationStrategy get migration => MigrationStrategy();

  @override
  int get schemaVersion => 1;
}
