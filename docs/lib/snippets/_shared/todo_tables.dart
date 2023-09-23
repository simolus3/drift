import 'package:drift/drift.dart';
import 'package:drift/internal/modular.dart';

import 'todo_tables.drift.dart';

// #docregion tables
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable().references(Categories, #id)();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}
// #enddocregion tables

class CanUseCommonTables extends ModularAccessor {
  CanUseCommonTables(super.attachedDatabase);

  $TodoItemsTable get todoItems => resultSet('todo_items');
  $CategoriesTable get categories => resultSet('categories');
}
