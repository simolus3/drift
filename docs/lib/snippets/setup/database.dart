// #docregion before_generation
import 'package:drift/drift.dart';

// #enddocregion before_generation

// #docregion open
// These imports are necessary to open the sqlite3 database
import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// ... the TodoItems table definition stays the same
// #enddocregion open

// #docregion before_generation
part 'database.g.dart';

// #docregion table
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable()();
}
// #enddocregion table
// #docregion open

@DriftDatabase(tables: [TodoItems])
class AppDatabase extends _$AppDatabase {
// #enddocregion before_generation
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
// #docregion before_generation
}
// #enddocregion before_generation, open

// #docregion open

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
// #enddocregion open

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
