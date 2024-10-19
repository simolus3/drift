// NOTE: Keep these tables in sync with setup.dart

// #docregion table
import 'package:drift/drift.dart';

part 'tables.g.dart';

class TodoItems extends Table {
  late final id = integer().autoIncrement()();
  late final title = text().withLength(min: 6, max: 32)();
  late final content = text().named('body')(); // (1)!
  late final category = integer().nullable().references(TodoCategory, #id)();
  late final createdAt = dateTime().nullable()(); // (2)!
}

class TodoCategory extends Table {
  late final id = integer().autoIncrement()();
  late final description = text()();
}
// #enddocregion table

// #docregion simple_schema_db
@DriftDatabase(tables: [TodoItems, TodoCategory, Items])
class Database extends _$Database {
  Database(super.e);

  @override
  int get schemaVersion => 1;
}
// #enddocregion simple_schema_db

class Table1 extends Table {
  // and more columns...
  // #docregion client_default
  late final useDarkMode = boolean().clientDefault(() => false)();
  // #enddocregion client_default
  // #docregion db_default
  late final content = text().withDefault(Constant('No content set'))();
  // #enddocregion db_default
  // #docregion optional_columns
  late final age = integer().nullable()();
  // #enddocregion optional_columns
  // #docregion unique_columns
  late final title = text().unique()();
  // #enddocregion unique_columns
  // #docregion withLength
  late final name = text().withLength(min: 1, max: 50)();
  // #enddocregion withLength
  // #docregion named_column
  late final createdAt = dateTime().named('created')();
  // #enddocregion named_column
}

class Table2 extends Table {
  // #docregion check_column
  late final Column<int> age = integer().check(age.isBiggerOrEqualValue(0))();
  // #enddocregion check_column
}

// #docregion autoIncrement
class Items extends Table {
  late final id = integer().autoIncrement()();
  late final title = text()();
}
// #enddocregion autoIncrement

// #docregion autoIncrementUse
Future<void> insertWithAutoIncrement(Database database) async {
  await database.items.insertAll([
    // Only the title is required here
    ItemsCompanion.insert(title: 'First entry'),
    ItemsCompanion.insert(title: 'Another item'),
  ]);

  final items = await database.items.all().get();
  // This prints [(id: 1, title: First entry), (id: 2, title: Another item)].
  // The id has been chosen by the database.
  print(items);
}
// #enddocregion autoIncrementUse

// #docregion unique_violation
Future<void> insertMultipleEntriesWithSameTitle(Database database) async {
  // Throws due to the unique violation on title
  await database.managers.todoItems.bulkCreate(
    (row) => [
      row(title: 'My todo item', content: 'Content'),
      row(title: 'My todo item', content: 'Another one?'),
    ],
  );
}
// #enddocregion unique_violation

// #docregion table_mixin
mixin TableMixin on Table {
  // Primary key column
  late final id = integer().autoIncrement()();

  // You can also add other columns here that you might want to apply to
  // multiple tables:
  late final createdAt = dateTime().withDefault(currentDateAndTime)();
}

class Posts extends Table with TableMixin {
  late final content = text()();
}
// #enddocregion table_mixin

// #docregion custom_pk
class Profiles extends Table {
  late final email = text()();

  @override
  Set<Column<Object>> get primaryKey => {email};
}
// #enddocregion custom_pk

// #docregion unique-table
class Reservations extends Table {
  late final reservationId = integer().autoIncrement()();

  late final room = text()();
  late final onDay = dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {room, onDay}
      ];
}
// #enddocregion unique-table

// #docregion generated_column
class Squares extends Table {
  late final length = integer()();
  late final width = integer()();
  late final area = integer().generatedAs(length * width)();
}
// #enddocregion generated_column

// #docregion generated_column_stored
class Boxes extends Table {
  late final length = integer()();
  late final width = integer()();
  late final area = integer().generatedAs(length * width, stored: true)();
}
// #enddocregion generated_column_stored

// #docregion custom_table_name
class Products extends Table {
  @override
  String get tableName => 'product_table';
}
// #enddocregion custom_table_name

class ColumnConstraint extends Table {
  // #docregion custom_column_constraint
  late final name =
      integer().nullable().customConstraint('COLLATE BINARY')(); // (1!)
  // #enddocregion custom_column_constraint

  // #docregion custom_column_constraint_not_nullable
  late final username = integer().customConstraint('NOT NULL COLLATE BINARY')();
  // #enddocregion custom_column_constraint_not_nullable
}

// #docregion custom-constraint-table
class TableWithCustomConstraints extends Table {
  late final foo = integer()();
  late final bar = integer()();

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (foo, bar) REFERENCES group_memberships ("group", user)',
      ];
}
// #enddocregion custom-constraint-table