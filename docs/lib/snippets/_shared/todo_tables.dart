import 'package:drift/drift.dart';
import 'package:drift/internal/modular.dart';

import 'todo_tables.drift.dart';

// #docregion tables
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable().references(Categories, #id)();
  // #enddocregion tables
  DateTimeColumn get dueDate => dateTime().nullable()();
  // #docregion tables
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}
// #enddocregion tables

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get birthDate => dateTime()();
}

class CanUseCommonTables extends ModularAccessor {
  CanUseCommonTables(super.attachedDatabase);

  $TodoItemsTable get todoItems => resultSet('todo_items');
  $CategoriesTable get categories => resultSet('categories');
  $UsersTable get users => resultSet('users');
}
