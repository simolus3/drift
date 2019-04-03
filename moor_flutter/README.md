# Moor

Moor is an easy to use, reactive persistence library for Flutter apps. Define your database tables in pure Dart and 
enjoy a fluent query API, auto-updating streams and more!

## Getting started
For a more detailed guide on using moor, checkout the [documentation](https://simolus3.github.io/moor/).
### Adding the dependency
First, add moor to your project's `pubspec.yaml`.
```yaml
dependencies:
  moor_flutter: # use the latest version

dev_dependencies:
  moor_generator: # use the latest versions
  build_runner: 
```

### Declaring tables
You can use the DSL included with this library to specify your libraries with simple
dart code:
```dart
import 'package:moor_flutter/moor_flutter.dart';

// assuming that your file is called filename.dart. This will give an error at first,
// but it's needed for moor to know about the generated code
part 'filename.g.dart'; 

// this will generate a table called "todos" for us. The rows of that table will
// be represented by a class called "Todo".
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 10)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable()();
}

// This will make moor generate a class called "Category" to represent a row in this table.
// By default, "Categorie" would have been used because it only strips away the trailing "s"
// in the table name.
@DataClassName("Category")
class Categories extends Table {
  
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
}

// this annotation tells moor to prepare a database class that uses both of the
// tables we just defined. We'll see how to use that database class in a moment.
@UseMoor(tables: [Todos, Categories])
class MyDatabase {
  
}
```

__⚠️ Note:__ The column definitions, the table name and the primary key must be known at
compile time. For column definitions and the primary key, the function must use the `=>`
operator and can't contain anything more than what's included in this `readme` and the
examples. Otherwise, the generator won't be able to know what's going on.

### Generating the code
Moor integrates with the dart `build` system, so you can generate all the code needed with 
`flutter packages pub run build_runner build`. If you want to continuously rebuild the generated code
whenever you change your code, run `flutter packages pub run build_runner watch` instead.
After running either command once, the moor generator will have created a class for your
database and data classes for your entities. To use it, change the `MyDatabase` class as
follows:
```dart
@UseMoor(tables: [Todos, Categories])
class MyDatabase extends _$MyDatabase {
  // we tell the database where to store the data with this constructor
  MyDatabase() : super(FlutterQueryExecutor.inDatabaseFolder(path: 'db.sqlite'));

  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 1; 
}
```
You can ignore the `schemaVersion` at the moment, the important part is that you can
now run your queries with fluent Dart code:
## Writing queries
```dart
// inside the database class:

  // loads all todo entries
  Future<List<Todo>> get allTodoEntries => select(todos).get();

  // watches all todo entries in a given category. The stream will automatically
  // emit new items whenever the underlying data changes.
  Stream<List<TodoEntry>> watchEntriesInCategory(Category c) {
    return (select(todos)..where((t) => t.category.equals(c.id))).watch();
  }
}
```
