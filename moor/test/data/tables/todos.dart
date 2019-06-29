import 'package:moor/moor.dart';

part 'todos.g.dart';

@DataClassName('TodoEntry')
class TodosTable extends Table {
  @override
  String get tableName => 'todos';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 4, max: 16).nullable()();
  TextColumn get content => text()();
  @JsonKey('target_date')
  DateTimeColumn get targetDate => dateTime().nullable()();

  IntColumn get category => integer().nullable()();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 6, max: 32)();
  BoolColumn get isAwesome => boolean().withDefault(const Constant(true))();

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

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (todo) REFERENCES todos(id)',
        'FOREIGN KEY (user) REFERENCES users(id)'
      ];
}

class TableWithoutPK extends Table {
  IntColumn get notReallyAnId => integer()();
  RealColumn get someFloat => real()();
}

@UseMoor(
  tables: [TodosTable, Categories, Users, SharedTodos, TableWithoutPK],
  queries: [
    Sql(
      'allTodosWithCategory',
      'SELECT t.*, c.id as catId, c."desc" as catDesc '
          'FROM todos t INNER JOIN categories c ON c.id = t.category',
    ),
    Sql(
        'todosForUser',
        'SELECT t.* FROM todos t '
            'INNER JOIN shared_todos st ON st.todo = t.id '
            'INNER JOIN users u ON u.id = st.user '
            'WHERE u.id = :user'),
  ],
)
class TodoDb extends _$TodoDb {
  TodoDb(QueryExecutor e) : super(e);

  @override
  MigrationStrategy get migration => MigrationStrategy();

  @override
  int get schemaVersion => 1;
}
