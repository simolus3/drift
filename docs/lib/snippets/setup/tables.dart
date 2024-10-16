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
@DriftDatabase(tables: [TodoItems, TodoCategory])
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
  late final createdAt = boolean().named('created')();
  // #enddocregion named_column
}

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