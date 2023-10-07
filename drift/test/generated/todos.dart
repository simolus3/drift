import 'package:drift/drift.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:uuid/uuid.dart';

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
  DateTimeColumn get targetDate => dateTime().nullable().unique()();

  IntColumn get category => integer().references(Categories, #id).nullable()();

  TextColumn get status => textEnum<TodoStatus>().nullable()();

  @override
  List<Set<Column>>? get uniqueKeys => [
        {title, category},
        {title, targetDate},
      ];
}

enum TodoStatus { open, workInProgress, done }

class Users extends Table with AutoIncrement {
  TextColumn get name => text().withLength(min: 6, max: 32).unique()();
  BoolColumn get isAwesome => boolean().withDefault(const Constant(true))();

  BlobColumn get profilePicture => blob()();
  DateTimeColumn get creationTime => dateTime()
      // ignore: recursive_getters
      .check(creationTime.isBiggerThan(Constant(DateTime.utc(1950))))
      .withDefault(currentDateAndTime)();
}

@DataClassName('Category')
class Categories extends Table with AutoIncrement {
  TextColumn get description =>
      text().named('desc').customConstraint('NOT NULL UNIQUE')();
  IntColumn get priority =>
      intEnum<CategoryPriority>().withDefault(const Constant(0))();

  TextColumn get descriptionInUpperCase =>
      text().generatedAs(description.upper())();
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
  Int64Column get webSafeInt => int64().nullable()();

  TextColumn get custom =>
      text().map(const CustomConverter()).clientDefault(_uuid.v4)();
}

class CustomRowClass {
  final int notReallyAnId;
  final double anotherName;
  final BigInt? webSafeInt;
  final MyCustomObject custom;

  final String? notFromDb;

  double get someFloat => anotherName;

  CustomRowClass._(this.notReallyAnId, this.anotherName, this.webSafeInt,
      this.custom, this.notFromDb);

  factory CustomRowClass.map(int notReallyAnId, double someFloat,
      {required MyCustomObject custom, BigInt? webSafeInt, String? notFromDb}) {
    return CustomRowClass._(
        notReallyAnId, someFloat, webSafeInt, custom, notFromDb);
  }
}

class PureDefaults extends Table {
  // name after keyword to ensure it's escaped properly
  TextColumn get txt =>
      text().named('insert').map(const CustomJsonConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {txt};
}

// example object used for custom mapping
class MyCustomObject {
  final String data;

  MyCustomObject(this.data);

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    return other is MyCustomObject && other.data == data;
  }
}

class CustomConverter extends TypeConverter<MyCustomObject, String> {
  const CustomConverter();

  @override
  MyCustomObject fromSql(String fromDb) {
    return MyCustomObject(fromDb);
  }

  @override
  String toSql(MyCustomObject value) {
    return value.data;
  }
}

class CustomJsonConverter extends CustomConverter
    with JsonTypeConverter2<MyCustomObject, String, Map> {
  const CustomJsonConverter();

  @override
  MyCustomObject fromJson(Map json) {
    return MyCustomObject(json['data'] as String);
  }

  @override
  Map toJson(MyCustomObject value) {
    return {'data': value.data};
  }
}

abstract class CategoryTodoCountView extends View {
  TodosTable get todos;
  Categories get categories;

  Expression<int> get categoryId => categories.id;
  Expression<String> get description =>
      categories.description + const Variable('!');
  Expression<int> get itemCount => todos.id.count();

  @override
  Query as() => select([categoryId, description, itemCount])
      .from(categories)
      .join([innerJoin(todos, todos.category.equalsExp(categories.id))])
    ..groupBy([categories.id]);
}

abstract class TodoWithCategoryView extends View {
  TodosTable get todos;
  Categories get categories;

  @override
  Query as() => select([todos.title, categories.description])
      .from(todos)
      .join([innerJoin(categories, categories.id.equalsExp(todos.category))]);
}

class WithCustomType extends Table {
  Column<UuidValue> get id => customType(const UuidType())();
}

class UuidType implements CustomSqlType<UuidValue> {
  const UuidType();

  @override
  String mapToSqlLiteral(UuidValue dartValue) {
    return "'$dartValue'";
  }

  @override
  Object mapToSqlParameter(UuidValue dartValue) {
    return dartValue;
  }

  @override
  UuidValue read(Object fromSql) {
    return fromSql as UuidValue;
  }

  @override
  String sqlTypeName(GenerationContext context) => 'uuid';
}

@DriftDatabase(
  tables: [
    TodosTable,
    Categories,
    Users,
    SharedTodos,
    TableWithoutPK,
    PureDefaults,
    WithCustomType,
  ],
  views: [
    CategoryTodoCountView,
    TodoWithCategoryView,
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
  TodoDb([QueryExecutor? e]) : super(e ?? _nullExecutor) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  @override
  MigrationStrategy migration = MigrationStrategy();

  @override
  DriftDatabaseOptions options = const DriftDatabaseOptions();

  @override
  int schemaVersion = 1;
}

@DriftAccessor(
  tables: [Users, SharedTodos, TodosTable],
  views: [TodoWithCategoryView],
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

QueryExecutor get _nullExecutor =>
    LazyDatabase(() => throw UnsupportedError('stub'));
