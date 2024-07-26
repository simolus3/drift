---
data:
  title: Native Drift (cross-platform)
  description: Run drift on both mobile and desktop
  weight: 1
template: layouts/docs/single

aliases:
  - docs/other-engines/vm/
---

{% assign snippets = "package:drift_docs/snippets/platforms/vm.dart.excerpt.json" | readString | json_decode %}

## Supported platforms

The `drift/native.dart` library uses the `sqlite3` package to send queries.
At the moment, that package supports iOS, macOS and Android out of the box. Most Linux
Distros have sqlite available as a shared library, those are supported as well. 

If you're shipping apps for Windows and Linux, it is recommended that you bundle a
`sqlite3.so` and `sqlite3.dll` file with your app. You can then make `drift`
support your setup by running this code before opening the database:

{% include "blocks/snippet" snippets = snippets name = "setup" %}

For Flutter apps, using the `drift_flutter` package as suggested in the
[setup instructions]({{ '../setup.md' | pageUrl }}) takes care of these steps.

## Drift-managed background isolates

Being a C library, SQLite runs SQL statements synchronously, blocking the
thread issuing a statement for IO or computations necessary to run statements.
Especially in mobile apps, this blocking nature means that the database should
not be accessed on the UI isolate directly, as this can cause dropped frames
or other UI issues.

When using `NativeDatabase.createInBackground` instead of the raw `NativeDatbase`
constructor, drift will set up a background isolate responsible for hosting the
database:

{% include "blocks/snippet" snippets = snippets name = "background-simple" %}

You can use the returned `QueryExecutor` with the constructor of your database
class. This means that the usage of the database doesn't change at all, only the
setup code needs to be adapted to use a background isolate.

### Using multiple read isolates

Using a single background isolate to host the database is sufficient for most
applications. In some cases though, it may be beneficial to use more than one
background isolate for the database:

1. Using multiple isolates can improve startup performance of your application
   if it runs a lot of queries when starting up.
2. If you have a mix of "expensive" reads (e.g. due to large data sizes in some
   tables) and small/faster reads, distributing them across multiple isolates
   ensures long-running reads don't impact others as much.
3. With a single thread, long-running writes or transactions block reads. This
   is not the case when using multiple isolates.

Efficiently using multiple isolates requires the use of [write-ahead logging](https://sqlite.org/wal.html) (WAL),
which allows a single writer and multiple readers to operate on the same database
file in parallel.
Not using WAL will cause "database is locked" errors when multiple isolates
access the same database.

An additional pool of readers can be enabled with the `readPool` argument on
`NativeDatabase.createInBackground`:

{% include "blocks/snippet" snippets = snippets name = "background-pool" %}

In this snippet, drift will spawn five isolates to host the database: One for writes,
and four additional ones only used for reads.
Note that transactions and `exclusively` blocks on the database will always use the
write isolate.

## Using native drift with an existing database {#using-moor-ffi-with-an-existing-database}

If your existing sqlite database is stored as a file, you can just use `NativeDatabase(thatFile)` - no further
changes are required.

If you want to load databases from assets or any other source, you can use a `LazyDatabase`.
It allows you to perform some async work before opening the database:

```dart
// before
NativeDatabase(File('...'));

// after
LazyDatabase(() async {
  final file = File('...');
  if (!await file.exists()) {
    // copy the file from an asset, or network, or any other source
  }
  return NativeDatabase(file);
});
```

Using existing databases is explained in more detail in [this example]({{ '../Examples/existing_databases.md' | pageUrl }}).

## Used compile options on Android

On Android, iOS and macOs, depending on `sqlite3_flutter_libs` will include a custom build of sqlite instead of
using the one from the system.
The chosen options help reduce binary size by removing features not used by drift. Important options are marked in bold.

- We use the `-O3` performance option
- __SQLITE_DQS=0__: This will make sqlite not accept double-quoted strings (and instead parse them as identifiers). This matches
  the behavior of drift and compiled queries
- __SQLITE_THREADSAFE=0__: Since the majority of Flutter apps only use one isolate, thread safety is turned off. Note that you
  can still use the [isolate api](../isolates.md") for background operations. As long as all
  database accesses happen from the same thread, there's no problem.
- SQLITE_DEFAULT_MEMSTATUS=0: The `sqlite3_status()` interfaces are not exposed by drift, so there's no point of having them.
- SQLITE_MAX_EXPR_DEPTH=0: Disables maximum depth when sqlite parses expressions, which can make the parser faster.
- `SQLITE_OMIT_AUTHORIZATION`, `SQLITE_OMIT_DECLTYPE`, __SQLITE_OMIT_DEPRECATED__, `SQLITE_OMIT_GET_TABLE`, `SQLITE_OMIT_LOAD_EXTENSION`,
  `SQLITE_OMIT_PROGRESS_CALLBACK`, `SQLITE_OMIT_SHARED_CACHE`, `SQLITE_OMIT_TCL_VARIABLE`, `SQLITE_OMIT_TRACE`: Disables features not supported
  by drift.
- `SQLITE_USE_ALLOCA`: Allocate temporary memory on the stack
- `SQLITE_UNTESTABLE`: Remove util functions that are only required to test sqlite3
- `SQLITE_HAVE_ISNAN`: Use the `isnan` function from the system instead of the one shipped with sqlite3.
- `SQLITE_ENABLE_FTS5`: Enable the [fts5](https://www.sqlite.org/fts5.html) engine for full-text search.
- `SQLITE_ENABLE_JSON1`: Enable the [json1](https://www.sqlite.org/json1.html) extension for json support in sql query.

For more details on sqlite compile options, see [their documentation](https://www.sqlite.org/compile.html).

## Drift-only functions {#moor-only-functions}

The `NativeDatabase` includes additional sql functions not available in standard sqlite:

- `pow(base, exponent)` and `power(base, exponent)`: This function takes two numerical arguments and returns `base` raised to the power of `exponent`.
  If `base` or `exponent` aren't numerical values or null, this function will return `null`. This function behaves exactly like `pow` in `dart:math`.
- `sqrt`, `sin`, `cos`, `tan`, `asin`, `acos`, `atan`: These functions take a single argument. If that argument is null or not a numerical value,
  returns null. Otherwise, returns the result of applying the matching function in `dart:math`.
- `regexp`: Wraps the Dart `RegExp` apis, so that `foo REGEXP bar` is equivalent to `RegExp(bar).hasMatch(foo)`. Note that we have to create a new
  `RegExp` instance for each `regexp` sql call, which can impact performance on large queries.
- `current_time_millis`: Returns the current unix timestamp as milliseconds. Equivalent to `DateTime.now().millisecondsSinceEpoch` in Dart.

Note that `NaN`, `-infinity` or `+infinity` are represented as `NULL` in sql.

When enabling the `moor_ffi` module in your [build options]({{ "../Generation options/index.md#available-extensions" | pageUrl }}),
the generator will allow you to use those functions in drift files or compiled queries.

To use those methods from Dart, you need to import `package:drift/extensions/native.dart`.
You can then use the additional functions like this:
```dart
import 'package:drift/drift.dart';
// those methods are hidden behind another import because they're only available with a NativeDatabase
import 'package:drift/extensions/native.dart';

class Coordinates extends Table {
  RealColumn get x => real()();
  RealColumn get y => real()();
}

// Can now be used like this:
Future<List<Coordinate>> findNearby(Coordinate center, int radius) {
  return (select(coordinates)..where((other) {
    // find coordinates where sqrt((center - x)² + (center.y - y)²) < radius
    final distanceSquared = sqlPow(center.x - row.x, 2) + sqlPow(center.y - row.y, 2);
    return sqlSqrt(distanceSquared).isLessThanValue(radius);
  })).get();
}
```

All the other functions are available under a similar name (`sqlSin`, `sqlCos`, `sqlAtan` and so on).
They have that `sql` prefix to avoid clashes with `dart:math`.

## Migrating from moor_flutter to `drift/native` {#migrating-from-moor_flutter-to-moor-ffi}

First, adapt your `pubspec.yaml`: You can remove the `moor_flutter` dependency and instead
add both the `drift` and `sqlite3_flutter_libs` dependencies:
{% assign versions = 'package:drift_docs/versions.json' | readString | json_decode %}

```yaml
dependencies:
 drift: ^{{ versions.drift }}
 sqlite3_flutter_libs:
 sqflite: ^1.1.7 # Still used to obtain the database location
dev_dependencies:
 drift_dev: ^{{ versions.drift_dev }}
```

Adapt your imports:

  - In the file where you created a `FlutterQueryExecutor`, replace the `moor_flutter` import
    with `package:drift/native.dart`.
  - In all other files where you might have imported `moor_flutter`, just import `package:drift/drift.dart`.

Replace the executor. This code:
```dart
FlutterQueryExecutor.inDatabaseFolder(path: 'db.sqlite')
```
can now be written as
```dart
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:path/path.dart' as p;

LazyDatabase(() async {
  final dbFolder = await getDatabasesPath();
  final file = File(p.join(dbFolder, 'db.sqlite'));
  return NativeDatabase(file);
})
```

Note: If you haven't shipped a version with `moor_flutter` to your users yet, you can drop the dependency
on `sqflite`. Instead, you can use `path_provider` which [works on Desktop](https://github.com/flutter/plugins/tree/master/packages/path_provider).
Please be aware that `FlutterQueryExecutor.inDatabaseFolder` might yield a different folder than
`path_provider` on Android. This can cause data loss if you've already shipped a version using
`moor_flutter`. In that case, using `getDatabasePath` from sqflite is the suggested solution.
