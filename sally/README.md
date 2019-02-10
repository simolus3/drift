# Sally
[![Build Status](https://travis-ci.com/simolus3/sally.svg?token=u4VnFEE5xnWVvkE6QsqL&branch=master)](https://travis-ci.com/simolus3/sally)

Sally is an easy to use and safe way to persist data for Flutter apps. It features
a fluent Dart DSL to describe tables and will generate matching database code that
can be used to easily read and store your app's data.

__Note:__ This library is in development and not yet available for general use on `pub`.

## Using this library
#### Adding the dependency
First, let's add sally to your prooject's `pubspec.yaml`:
```yaml
dependencies:
  sally:
    git:
      url: 
      path: sally/

dev_dependencies:
  sally_generator:
    git:
      url:
      path: sally_generator/
  build_runner:
```
We're going to use the `sally` library to specify tables and write data. The
`sally_generator` library will take care of generating the necessary code so the
library knows how your table structure looks like.

#### Declaring tables
You can use the DSL included with this library to specify your libraries with simple
dart code:
```dart
import 'package:sally/sally.dart';

// assuming that your file is called filename.dart. This will give an error at first,
// but it's needed for sally to know about the generated code
part 'filename.g.dart'; 

class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 6, max: 10)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer()();
}

class Categories extends Table {
  @override
  String get tableName => 'todo_categories';
  
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
}

@UseSally(tables: [Todos, Categories])
class MyDatabase {
  
}
```

__⚠️ Warning:__ Even though it might look like it, the content of a `Table` class does not support full Dart code. It can only
be used to declare the table name, it's primary keys and columns. The code inside of a table class will never be 
executed. Instead, the generator will take a look at your table classes to figure out how their structure looks like.
This won't work if the body of your tables is not constant. This should not be problem, but please be aware of this.

#### Generating the code
Sally integrates with the dart `build` system, so you can generate all the code needed with 
`flutter packages pub run build_runner build`. If you want to continously rebuild the code
whever you change your code, run `flutter packages pub run build_runner watch` instead.
After running either command once, sally generator will have created a class for your
database and data classes for your entities. To use it, change the `MyDatabase` class as
follows:
```dart
@UseSally(tables: [Todos, Categories])
class MyDatabase extends _$MyDatabase {
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy();
}
```
You can ignore these two getters there at the moment, the imporant part is that you can
now run your queries with fluent Dart code:
```dart
class MyDatabase extends _$MyDatabase {
  // .. the getters that have been defined above still need to be here

  Future<List<Todo>> get allTodoEntries => select(todos).get();

  Future<void> deleteCategory(Category toDelete) async {
    await (delete(todos)..where((entry) => entry.category.equalsVal(category.id))).go();
    await (delete(categories)..where((cat) => cat.id.equalsVal(toDelete.id))).go();
  }
}
```

## TODO-List
If you have suggestions for new features or any other questions, feel free to
create an issue.

##### Before this library can be released
- Insert and update statements
- Custom primary keys
- Stabilize all end-user APIs
- Support default values and expressions, auto-increment
- Allow custom table names for the generated dart types
##### Definitely planned for the future
- Allow using DAOs instead of having to put everything in the main database
class.
- Auto-updating streams
- Support more Datatypes: We should at least support `DateTime` and `Uint8List`,
supporting floating point numbers as well would be awesome
- Nullable / non-nullable datatypes
  - DSL API
  - Support in generator
  - Use in queries (`IS NOT NULL`)
- Verify constraints (text length, nullability, etc.) before inserting or
  deleting data.
- Support Dart VM apps
- References
- Table joins
##### Interesting stuff that would be nice to have
- `GROUP BY` grouping functions 
- Support for different database engines
  - Support webapps via `AlaSQL` or a different engine