// ignore_for_file: unused_element
// #docregion flutter,sqlite3,postgres,before_generation
import 'package:drift/drift.dart';
// #enddocregion flutter,sqlite3,postgres,before_generation

// #docregion flutter
import 'package:drift_flutter/drift_flutter.dart';
// #enddocregion flutter
// #docregion sqlite3
import 'dart:io';
import 'package:drift/native.dart';
// #enddocregion sqlite3
// #docregion postgres
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;
// #enddocregion postgres

// #docregion flutter,sqlite3,postgres,before_generation

part 'database.g.dart';

// #docregion table
class TodoItems extends Table {
  late final id = integer().autoIncrement()();
  late final title = text().withLength(min: 6, max: 32)();
  late final content = text().named('body')();
  @ReferenceName("mainCategory")
  late final category = integer().nullable().references(TodoCategory, #id)();
  @ReferenceName("secondaryCategory")
  late final secondaryCategory =
      integer().nullable().references(TodoCategory, #id)();
  late final createdAt = dateTime().nullable()();
}

class TodoCategory extends Table {
  late final id = integer().autoIncrement()();
  late final description = text()();
}

// #enddocregion before_generation
// #enddocregion table
@DriftDatabase(tables: [TodoItems, TodoCategory])
class AppDatabase extends _$AppDatabase {
  // After generating code, this class needs to define a `schemaVersion` getter
  // and a constructor telling drift where the database should be stored.
  // These are described in the getting started guide: https://drift.simonbinder.eu/getting-started/#open
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // #enddocregion flutter,sqlite3,postgres
  static QueryExecutor _openConnection() {
    throw 'should not show as snippet';
  }
}

class OpenFlutter {
// #docregion flutter
  static QueryExecutor _openConnection() {
    // `driftDatabase` from `package:drift_flutter` stores the database in
    // `getApplicationDocumentsDirectory()`.
    return driftDatabase(name: 'my_database');
  }
}
// #enddocregion flutter

class OpenPostgres {
// #docregion postgres
  static QueryExecutor _openConnection() {
    return PgDatabase(
      endpoint: pg.Endpoint(
        host: 'localhost',
        database: 'database',
        username: 'dart',
        password: 'mysecurepassword',
      ),
    );
  }
}
// #enddocregion postgres

class OpenSqlite3 {
// #docregion sqlite3
  static QueryExecutor _openConnection() {
    return NativeDatabase.createInBackground(File('path/to/your/database'));
  }
}
// #enddocregion sqlite3

class WidgetsFlutterBinding {
  static void ensureInitialized() {}
}

// #docregion use
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();

  await database.into(database.todoItems).insert(TodoItemsCompanion.insert(
        title: 'todo: finish drift setup',
        content: 'We can now write queries and define our own tables.',
      ));
  List<TodoItem> allItems = await database.select(database.todoItems).get();

  print('items in database: $allItems');
}
// #enddocregion use
