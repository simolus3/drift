// ignore_for_file: unused_local_variable, unused_element

import 'dart:convert';

import 'package:drift/drift.dart';

part 'tables.g.dart';

// #docregion simple_schema
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()(); // (1)!
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category =>
      integer().nullable().references(TodoCategory, #id)();
  DateTimeColumn get createdAt => dateTime().nullable()(); // (2)!
}

class TodoCategory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
}
// #enddocregion simple_schema

// #docregion simple_schema_db
@DriftDatabase(tables: [TodoItems, TodoCategory])
class Database extends _$Database {
  Database(super.e);

  @override
  int get schemaVersion => 1;
}
// #enddocregion simple_schema_db

// #docregion references
class Albums extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()();
  late final artist = integer().references(Artists, #id)();
}

class Artists extends Table {
  late final id = integer().autoIncrement()();
  late final name = text()();
}
// #enddocregion references

bool isInDarkMode() => false;

class Table1 extends Table {
  // #docregion client_default
  late final useDarkMode = boolean().clientDefault(() => false)();
  // #enddocregion client_default
  // #docregion db_default
  late final creationTime = dateTime().withDefault(currentDateAndTime)();
  // #enddocregion db_default
  // #docregion optional_columns
  late final age = integer().nullable()();
  // #enddocregion optional_columns
  // #docregion unique_columns
  late final username = text().unique()();
  // #enddocregion unique_columns
  // #docregion withLength
  late final name = text().withLength(min: 1, max: 50)();
  // #enddocregion withLength
  // #docregion named_column
  late final isAdmin = boolean().named('admin')();
  // #enddocregion named_column
}

class Table2 extends Table {
  // #docregion check_column
  late final Column<int> age = integer().check(age.isBiggerOrEqualValue(0))();
  // #enddocregion check_column
}

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

// #docregion pk-example
// #enddocregion pk-example

// #docregion custom_table_name
class Products extends Table {
  @override
  String get tableName => 'product_table';
}
// #enddocregion custom_table_name

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

class GroupMemberships extends Table {
  late final group = integer()();
  late final user = integer()();
}

// #docregion table_mixin
mixin TableMixin on Table {
  // Primary key column
  late final id = integer().autoIncrement()();

  // Column for created at timestamp
  late final createdAt = dateTime().withDefault(currentDateAndTime)();
}

class Posts extends Table with TableMixin {
  late final content = text()();
}
// #enddocregion table_mixin

class ColumnConstraint extends Table {
  // #docregion custom_column_constraint
  late final name = text().nullable().customConstraint('COLLATE BINARY')();
  // #enddocregion custom_column_constraint

  // #docregion custom_column_constraint_not_nullable
  late final username = text().customConstraint('NOT NULL COLLATE BINARY')();
  // #enddocregion custom_column_constraint_not_nullable
}

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

// #docregion autoIncrement
class Items extends Table {
  late final id = integer().autoIncrement()();
  late final title = text()();
}
// #enddocregion autoIncrement

Future<void> insertWithAutoIncrement(CatDatabase database) async {
  // #docregion autoIncrementUse
  await database.items.insertAll([
    // Only the title is required here
    ItemsCompanion.insert(title: 'First entry'),
    ItemsCompanion.insert(title: 'Another item'),
  ]);

  final items = await database.items.all().get();
  // This prints [(id: 1, title: First entry), (id: 2, title: Another item)].
  // The id has been chosen by the database.
  print(items);
  // #enddocregion autoIncrementUse
}

Future<void> insertWithAutoIncrementManager(CatDatabase database) async {
  // #docregion autoIncrementUseManager
  await database.managers.items.bulkCreate((c) => [
        c(title: 'First entry'),
        c(title: 'Another item'),
      ]);

  final items = await database.managers.items.get();
  // This prints [(id: 1, title: First entry), (id: 2, title: Another item)].
  // The id has been chosen by the database.
  print(items);
  // #enddocregion autoIncrementUseManager
}

@DriftDatabase(tables: [Reservations, Items])
class CatDatabase extends _$CatDatabase {
  CatDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

// #docregion index
@TableIndex(name: 'user_name', columns: {#name})
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}
// #enddocregion index

// #docregion indexsql
@TableIndex.sql('''
  CREATE INDEX pending_orders ON orders (creation_time)
    WHERE status == 'pending';
''')
class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get totalAmount => integer()();
  DateTimeColumn get creationTime => dateTime()();
  TextColumn get status => text()();
}
// #enddocregion indexsql

// #docregion references

// #enddocregion references
