import 'package:moor/moor.dart';

part 'todos.g.dart';

@DataClassName('TodoEntry')
class TodosTable extends Table {
  @override
  String get tableName => 'todos';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 4, max: 16).nullable()();
  TextColumn get content => text()();
  DateTimeColumn get targetDate => dateTime().nullable()();

  IntColumn get category => integer().nullable()();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 6, max: 32)();
  BoolColumn get isAwesome => boolean()();

  BlobColumn get profilePicture => blob()();
  DateTimeColumn get creationTime =>
      dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description =>
      text().named('desc').customConstraint('NOT NULL UNIQUE')();
}

class SharedTodos extends Table {
  IntColumn get todo => integer()();
  IntColumn get user => integer()();

  @override
  Set<Column> get primaryKey => {todo, user};
}

@UseMoor(tables: [TodosTable, Categories, Users, SharedTodos])
class TodoDb extends _$TodoDb {
  TodoDb(QueryExecutor e) : super(e);

  @override
  MigrationStrategy get migration => MigrationStrategy();

  @override
  int get schemaVersion => 1;
}
