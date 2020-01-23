---
title: "Getting Started"
linkTitle: "Getting Started"
weight: 2
description: Simple guide to get a moor project up and running

aliases:
  - /getting-started/  # Used to have this url
---

_Note:_ If you prefer a tutorial video, Reso Coder has made a detailed video explaining
how to get started. You can watch it [here](https://youtu.be/zpWsedYMczM).

## Adding the dependency
First, lets add moor to your project's `pubspec.yaml`.
At the moment, the current version of `moor` is [![Moor version](https://img.shields.io/pub/v/moor.svg)](https://pub.dartlang.org/packages/moor),
`moor_ffi` is at [![Moor version](https://img.shields.io/pub/v/moor_ffi.svg)](https://pub.dartlang.org/packages/moor_ffi)
and the latest version of `moor_generator` is [![Generator version](https://img.shields.io/pub/v/moor_generator.svg)](https://pub.dartlang.org/packages/moor_generator)

```yaml
dependencies:
  moor: # use the latest version
  moor_ffi: # use the latest version
  path_provider:
  path:

dev_dependencies:
  moor_generator: # use the latest version
  build_runner: 
```

If you're wondering why so many packages are necessary, here's a quick overview over what each package does:

- `moor`: This is the core package defining most apis
- `moor_ffi`: Contains code that will run the actual queries
- `path_provider` and `path`: Used to find a suitable location to store the database. Maintained by the Flutter and Dart team
- `moor_generator`: Generates query code based on your tables
- `build_runner`: Common tool for code-generation, maintained by the Dart team

Note that, on Android, the NDK is required. You can easily install the NDK and CMake from the SDK Manager in Android Studio
by following the instructions [here](https://developer.android.com/studio/projects/install-ndk.md).

{{% changed_to_ffi %}}

### Declaring tables
Using moor, you can model the structure of your tables with simple dart code:
```dart
import 'package:moor/moor.dart';

// assuming that your file is called filename.dart. This will give an error at first,
// but it's needed for moor to know about the generated code
part 'filename.g.dart';

// this will generate a table called "todos" for us. The rows of that table will
// be represented by a class called "Todo".
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
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
operator and can't contain anything more than what's included in the documentation and the
examples. Otherwise, the generator won't be able to know what's going on.

## Generating the code
Moor integrates with Dart's `build` system, so you can generate all the code needed with 
`flutter packages pub run build_runner build`. If you want to continuously rebuild the generated code
whever you change your code, run `flutter packages pub run build_runner watch` instead.
After running either command once, the moor generator will have created a class for your
database and data classes for your entities. To use it, change the `MyDatabase` class as
follows:
```dart
// These imports are only needed to open the database
import 'package:moor_ffi/moor_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return VmDatabase(file);
  });
}

@UseMoor(tables: [Todos, Categories])
class MyDatabase extends _$MyDatabase {
  // we tell the database where to store the data with this constructor
  MyDatabase() : super(_openConnection());

  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 1;
}
```

Congratulations! You're now ready to use all of moor. See the articles below for further reading.
The ["Writing queries"]({{< relref "writing_queries.md" >}}) article contains everything you need
to know to write selects, updates and inserts in moor!
