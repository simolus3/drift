import 'dart:typed_data';

import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:uuid/uuid.dart' hide UuidValue;

part 'todos.g.dart';

extension type RowId._(int id) {
  const RowId(this.id);
}

mixin AutoIncrement on Table {
  IntColumn get id =>
      integer().autoIncrement().map(TypeConverter.extensionType<RowId, int>());
}

@DataClassName('TodoEntry')
class TodosTable extends Table with AutoIncrement {
  @override
  String get tableName => 'todos';

  TextColumn get title => text().withLength(min: 4, max: 16).nullable();
  TextColumn get content => text();
  DateTimeColumn get targetDate => dateTime().nullable().unique();
  @ReferenceName("todos")
  IntColumn get category => integer()
      .references(Categories, #id, initiallyDeferred: true)
      .map(TypeConverter.extensionType<RowId, int>())
      .nullable();

  TextColumn get status => textEnum<TodoStatus>().nullable();

  @override
  List<Set<Column>>? get uniqueKeys => [
    {title, category},
    {title, targetDate},
  ];
}

enum TodoStatus { open, workInProgress, done }

class Users extends Table with AutoIncrement {
  TextColumn get name => text().withLength(min: 6, max: 32).unique();
  BoolColumn get isAwesome => boolean().withDefault(const Literal(true));

  BlobColumn get profilePicture => blob();
  DateTimeColumn get creationTime => dateTime()
      // ignore: recursive_getters
      .check(creationTime.isGreaterThan(Literal(DateTime.utc(1950))))
      .withDefault(currentDateAndTime);
}

@DataClassName('Category')
@TableIndex(
  name: 'categories_desc',
  columns: {
    IndexedColumn(#description, orderBy: OrderingMode.desc),
    #priority,
  },
)
class Categories extends Table with AutoIncrement {
  TextColumn get description =>
      text().named('desc').customConstraint('NOT NULL UNIQUE');
  IntColumn get priority =>
      intEnum<CategoryPriority>().withDefault(const Literal(0));

  TextColumn get descriptionInUpperCase =>
      text().generatedAs(description.upper());
}

enum CategoryPriority { low, medium, high }

class SharedTodos extends Table {
  IntColumn get todo => integer();
  IntColumn get user => integer();

  @override
  Set<Column> get primaryKey => {todo, user};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (todo) REFERENCES todos(id)',
    'FOREIGN KEY (user) REFERENCES users(id)',
  ];
}

class CustomRowClass {
  final int notReallyAnId;
  final double anotherName;
  final BigInt? webSafeInt;
  final MyCustomObject custom;

  final String? notFromDb;

  double get someFloat => anotherName;

  CustomRowClass._(
    this.notReallyAnId,
    this.anotherName,
    this.webSafeInt,
    this.custom,
    this.notFromDb,
  );

  factory CustomRowClass.map(
    int notReallyAnId,
    double someFloat, {
    required MyCustomObject custom,
    BigInt? webSafeInt,
    String? notFromDb,
  }) {
    return CustomRowClass._(
      notReallyAnId,
      someFloat,
      webSafeInt,
      custom,
      notFromDb,
    );
  }
}

class PureDefaults extends Table {
  // name after keyword to ensure it's escaped properly
  TextColumn get txt =>
      text().named('insert').map(const CustomJsonConverter()).nullable();

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

const _uuid = Uuid();

@UseRowClass(CustomRowClass, constructor: 'map', generateInsertable: true)
class TableWithoutPK extends Table {
  IntColumn get notReallyAnId => integer();
  RealColumn get someFloat => real();
  Int64Column get webSafeInt => int64().nullable();

  TextColumn get custom =>
      text().map(const CustomConverter()).clientDefault(_uuid.v4);
}

class TableWithEveryColumnType extends Table with AutoIncrement {
  BoolColumn get aBool => boolean().nullable();
  DateTimeColumn get aDateTime => dateTime().nullable();
  TextColumn get aText => text().nullable();
  IntColumn get anInt => integer().nullable();
  Int64Column get anInt64 => int64().nullable();
  RealColumn get aReal => real().nullable();
  BlobColumn get aBlob => blob().nullable();
  IntColumn get anIntEnum => intEnum<TodoStatus>().nullable();
  TextColumn get aTextWithConverter => text()
      .named('insert')
      .map(const CustomJsonConverter())
      .nullable()
      .nullable();
}

class Department extends Table {
  IntColumn get id => integer().autoIncrement();
  TextColumn get name => text().nullable();
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
    with JsonTypeConverter2<MyCustomObject, String, Map<String, Object?>> {
  const CustomJsonConverter();

  @override
  MyCustomObject fromJson(Map<String, Object?> json) {
    return MyCustomObject(json['data'] as String);
  }

  @override
  Map<String, Object?> toJson(MyCustomObject value) {
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
  BaseSelectStatement as() => select([categoryId, description, itemCount])
      .from(categories)
      .innerJoin(todos, on: todos.category.equalsExp(categories.id))
      .groupBy([categories.id]);
}

abstract class TodoWithCategoryView extends View {
  TodosTable get todos;
  Categories get categories;

  @override
  BaseSelectStatement as() => select([todos.title, categories.description])
      .from(todos)
      .innerJoin(categories, on: categories.id.equalsExp(todos.category));
}

/// Custom `UuidValue` wrapper because the one from `package:uuid` is marked as
/// experimental.
extension type const UuidValue(String value) implements Object {}

class WithCustomType extends Table {
  Column<UuidValue> get id => col(uuidType);
}

final class UuidType extends PhysicalSqlType<UuidValue> {
  final bool isSupported;

  const UuidType({required this.isSupported});

  @override
  String get typeName => isSupported ? 'uuid' : 'text';

  @override
  String sqlLiteral(UuidValue value) {
    return "'$value'";
  }

  @override
  Object? sqlParameter(UuidValue? dartValue) {
    return dartValue?.toString();
  }

  @override
  UuidValue dartValue(Object fromSql) {
    if (isSupported) {
      return fromSql as UuidValue;
    } else {
      return UuidValue(fromSql as String);
    }
  }
}

final uuidType = SqlType<UuidValue>.dialectSpecific(
  fallback: UuidType(isSupported: false),
  overrides: {.postgres: UuidType(isSupported: true)},
);

@DriftDatabase(
  tables: [
    Categories,
    SharedTodos,
    Users,
    TodosTable,
    TableWithEveryColumnType,
    TableWithoutPK,
    PureDefaults,
    WithCustomType,
    Department,
  ],
  views: [CategoryTodoCountView, TodoWithCategoryView],
  daos: [SomeDao],
  queries: {
    'withIn': 'SELECT * FROM todos WHERE title = ?2 OR id IN ? OR title = ?1',
  },
)
final class TodoDb extends _$TodoDb {
  SqliteOptions sqliteOptions = const SqliteOptions();

  TodoDb([DriftConnection? e]) : super(e ?? _nullConnection) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  @override
  MigrationStrategy migration = MigrationStrategy();

  @override
  Map<KnownSqlDialect, Object> get dialectOptions => {
    KnownSqlDialect.sqlite: sqliteOptions,
  };

  @override
  int schemaVersion = 1;
}

@DriftAccessor(
  tables: [Users, SharedTodos, TodosTable],
  views: [TodoWithCategoryView],
  queries: {
    'todosForUser':
        'SELECT t.* FROM todos t '
        'INNER JOIN shared_todos st ON st.todo = t.id '
        'INNER JOIN users u ON u.id = st.user '
        'WHERE u.id = :user',
  },
)
final class SomeDao extends DatabaseAccessor<TodoDb> with _$SomeDaoMixin {
  SomeDao(super.db);
}

DriftConnection get _nullConnection => DriftConnection(
  dialect: SqliteDialect.new,
  openConnection: () => throw UnsupportedError('stub'),
);
