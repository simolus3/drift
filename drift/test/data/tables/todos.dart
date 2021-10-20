import 'package:drift/drift.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:uuid/uuid.dart';

import '../utils/null_executor.dart';

part 'todos.g.dart';

mixin AutoIncrement on Table {
  IntColumn get id => integer().autoIncrement()();
}

@DataClassName('TodoEntry')
class TodosTable extends Table with AutoIncrement {
  @override
  String get tableName => 'todos';

  TextColumn get title => text().withLength(min: 4, max: 16).nullable()();
  TextColumn get content => text()();
  @JsonKey('target_date')
  DateTimeColumn get targetDate => dateTime().nullable()();

  IntColumn get category => integer().references(Categories, #id).nullable()();
}

class Users extends Table with AutoIncrement {
  TextColumn get name => text().withLength(min: 6, max: 32)();
  BoolColumn get isAwesome => boolean().withDefault(const Constant(true))();

  BlobColumn get profilePicture => blob()();
  DateTimeColumn get creationTime =>
      dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Category')
class Categories extends Table with AutoIncrement {
  TextColumn get description =>
      text().named('desc').customConstraint('NOT NULL UNIQUE')();
  IntColumn get priority =>
      intEnum<CategoryPriority>().withDefault(const Constant(0))();
}

enum CategoryPriority { low, medium, high }

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

const _uuid = Uuid();

@UseRowClass(CustomRowClass, constructor: 'map', generateInsertable: true)
class TableWithoutPK extends Table {
  IntColumn get notReallyAnId => integer()();
  RealColumn get someFloat => real()();

  TextColumn get custom =>
      text().map(const CustomConverter()).clientDefault(_uuid.v4)();
}

class CustomRowClass {
  final int notReallyAnId;
  final double anotherName;
  final MyCustomObject custom;

  final String? notFromDb;

  double get someFloat => anotherName;

  CustomRowClass._(
      this.notReallyAnId, this.anotherName, this.custom, this.notFromDb);

  factory CustomRowClass.map(int notReallyAnId, double someFloat,
      {required MyCustomObject custom, String? notFromDb}) {
    return CustomRowClass._(notReallyAnId, someFloat, custom, notFromDb);
  }
}

class PureDefaults extends Table {
  // name after keyword to ensure it's escaped properly
  TextColumn get txt => text().named('insert').nullable()();

  @override
  Set<Column> get primaryKey => {txt};
}

// example object used for custom mapping
class MyCustomObject {
  final String data;

  MyCustomObject(this.data);
}

class CustomConverter extends TypeConverter<MyCustomObject, String> {
  const CustomConverter();

  @override
  MyCustomObject? mapToDart(String? fromDb) {
    return fromDb == null ? null : MyCustomObject(fromDb);
  }

  @override
  String? mapToSql(MyCustomObject? value) {
    return value?.data;
  }
}

@DriftDatabase(
  tables: [
    TodosTable,
    Categories,
    Users,
    SharedTodos,
    TableWithoutPK,
    PureDefaults,
  ],
  daos: [SomeDao],
  queries: {
    'allTodosWithCategory': 'SELECT t.*, c.id as catId, c."desc" as catDesc '
        'FROM todos t INNER JOIN categories c ON c.id = t.category',
    'deleteTodoById': 'DELETE FROM todos WHERE id = ?',
    'withIn': 'SELECT * FROM todos WHERE title = ?2 OR id IN ? OR title = ?1',
    'search':
        'SELECT * FROM todos WHERE CASE WHEN -1 = :id THEN 1 ELSE id = :id END',
    'findCustom': 'SELECT custom FROM table_without_p_k WHERE some_float < 10',
  },
)
class TodoDb extends _$TodoDb {
  TodoDb([QueryExecutor? e]) : super(e ?? const NullExecutor()) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  TodoDb.connect(DatabaseConnection connection) : super.connect(connection) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  @override
  MigrationStrategy migration = MigrationStrategy();

  @override
  int get schemaVersion => 1;
}

@DriftAccessor(
  tables: [Users, SharedTodos, TodosTable],
  queries: {
    'todosForUser': 'SELECT t.* FROM todos t '
        'INNER JOIN shared_todos st ON st.todo = t.id '
        'INNER JOIN users u ON u.id = st.user '
        'WHERE u.id = :user'
  },
)
class SomeDao extends DatabaseAccessor<TodoDb> with _$SomeDaoMixin {
  SomeDao(TodoDb db) : super(db);
}
