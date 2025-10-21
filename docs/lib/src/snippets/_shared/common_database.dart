import 'package:drift/drift.dart';

import 'todo_tables.dart';

import 'common_database.drift.dart';
import 'todo_tables.drift.dart';

// To hide the fact that this is using the modular builder...
typedef _$MyDatabase = $MyDatabase;

// #docregion db
@DriftDatabase(tables: [TodoItems, Categories])
class MyDatabase extends _$MyDatabase {
  // the schemaVersion getter and the constructor from the previous page
  // have been omitted.
  // #enddocregion db
  MyDatabase(super.e);
  @override
  int get schemaVersion => throw UnimplementedError();
  // #docregion db

  // loads all todo entries
  Future<List<TodoItem>> get allTodoItems => select(todoItems).get();

  // watches all todo entries in a given category. The stream will automatically
  // emit new items whenever the underlying data changes.
  Stream<List<TodoItem>> watchEntriesInCategory(Category c) {
    return (select(todoItems)..where((t) => t.category.equals(c.id))).watch();
  }
}

// #enddocregion db
