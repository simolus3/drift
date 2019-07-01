# Moor

Moor is an easy to use, reactive persistence library for Flutter apps. Define your database tables in pure Dart and 
enjoy a fluent query API, auto-updating streams and more!

Here are just some of the many features moor provides to make dealing with persistence much
easier:

## Declarative tables
With moor, you can declare your tables in pure dart without having to miss out on advanced sqlite
features. Moor will take care of writing the `CREATE TABLE` statements when the database is created.

## Fluent queries
Thanks to the power of Dart build system, moor will let you write typesafe queries:
```dart
Future<User> userById(int id) {
  return (select(users)..where((user) => user.id.equals(id))).getSingle();
  // runs SELECT * FROM users WHERE id = ?, automatically binds the parameter
  // and parses the result row.
}
```

No more hard to debug typos in sql, no more annoying to write mapping code - moor takes
care of all the boring parts. Moor supports features like order by statements, limits and
even joins with this api.

## Prefer SQL? Moor got you covered
Moor contains a powerful sql parser and analyzer, allowing it to create typesafe APIs for
all your sql queries:
```dart
@UseMoor(
  tables: [Categories],
  queries: {
    'categoryById': 'SELECT * FROM categories WHERE id = :id'
  },
)
class MyDatabase extends _$MyDatabase {
// the _$MyDatabase class will have the categoryById(int id) and watchCategoryById(int id)
// methods that execute the sql and parse its result into a generated class.
```
All queries are validated and analyzed during build-time, so that moor can provide hints
about potential errors quickly and generate efficient mapping code once.

## Auto-updating streams
For all your queries, moor can generate a `Stream` that will automatically emit new results
whenever the underlying data changes. This is first-class feature that perfectly integrates
with custom queries, daos and all the other features. Having an auto-updating single source
of truth makes managing perstistent state much easier!

## And much moor...
Moor also supports transactions, DAOs, powerful helpers for migrations, batched inserts and
many more features that makes writing persistence code much easier.

## Getting started
For a more detailed guide on using moor, check out the [documentation](https://moor.simonbinder.eu/).
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

Visit the detailed [documentation](https://moor.simonbinder.eu/) to learn about advanced
features like transactions, DAOs, custom queries and more.