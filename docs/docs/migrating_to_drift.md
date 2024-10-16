---

title: Migrate to Drift
description: Resources on how to migrate to drift from other database packages.

---

The Dart and Flutter ecosystem provides great packages to access sqlite3 databases:
[sqflite](https://pub.dev/packages/sqflite) uses Flutter-specific platform channels
talking to sqlite3 libraries from the operating system, while [sqlite3](https://pub.dev/packages/sqlite3)
uses `dart:ffi` to bind to the native library without platform channels.
Drift is built ontop of these lower-level packages to provide additional
features, such as:

- Type-safe access to your database, giving you resolved classes for queries instead of
  a dynamic `List<Map<String, Object?>>` that you have to parse yourself.
- A complete [query builder](./Dart%20API/manager.md) capable of expressing
  even complex SQL statements in Dart.
- Auto-updating streams for your queries.
- Easier [transaction management](dart_api/transactions.md).
- [Assisted migrations](Migrations/step_by_step.md) and [reliable unit tests](Migrations/tests.md) for your migrations.
- Compile-time [analysis and lints for your SQL](sql_api/drift_files.md).
- Efficient cross-platform implementations thanks to builtin [isolate](isolates.md) and [web worker](Platforms/web.md) support.
- Multi-dialect support, allowing you to [re-use database code](Examples/server_sync.md) between
  your app and your backend.

`sqflite` and `sqlite3` are amazing packages, and they are great tools for applications
using sqlite3.
Especially once the database becomes more complex, the additional features provided
by drift make managing and querying the database much easier.
For those interested in adopting drift while currently using another package to manage
sqlite databases, this page provides guides on how to migrate to drift.

## Preparations

First, add a dependency on `drift` and related packages used to generate code to your app:






```yaml
dependencies:
  drift: ^{{ versions.drift }}

dev_dependencies:
  drift_dev: ^{{ versions.drift_dev }}
  build_runner: ^{{ versions.build_runner }}
```

Or, simply run this:

```
dart pub add drift dev:drift_dev dev:build_runner
```

To start with code generation, drift requires a database class that you define.
This class references the tables to include as well as logic describing how to
open it.
Create a file called `database.dart` (every name is possible of course, just remember
to update the `part` statement when using a different file name) somewhere under
`lib/` and use the following snippet

{{ load_snippet('start','lib/snippets/setup/migrate_to_drift/database.dart.excerpt.json') }}

To fix the errors in that snippet, generate code with

```
dart run build_runner build
```

This will generate the `database.g.dart` file with the relevant superclass.

### Opening a drift database

A suitable implementation of `_openDatabase` depends on the database you've previously used.
If you have been using `sqflite` directly, you can use a drift implementation based on `sqflite`.
For that, run `dart pub add drift_sqflite`.
Then, if you have previously been using

```dart
var databasesPath = await getDatabasesPath();
var path = join(databasesPath, 'demo.db');
var database = await openDatabase(path, version: ...);
```

You can open the same database with drift like this:

```dart
import 'package:drift_sqflite/drift_sqflite.dart';

static QueryExecutor _openDatabase() {
  return SqfliteQueryExecutor.inDatabaseFolder(path: 'db.sqlite');
}
```

On the other hand, if you have previously been using `package:sqlite3` or `package:sqlite_async`,
your database code may have looked like this:

```dart
var dbFolder = await getApplicationDocumentsDirectory();
var path = p.join(dbFolder.path, 'demo.db');
var database = sqlite3.open(path);
```

Here, a matching drift implementation would be:

```dart
import 'package:drift/native.dart';

static QueryExecutor _openDatabase() {
  return LazyDatabase(() async {
    var dbFolder = await getApplicationDocumentsDirectory();
    var file = File(p.join(dbFolder.path, 'db.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
```

## Telling drift about your database

The current snippets allow opening your existing database through drift APIs, but drift
doesn't know anything about your tables yet.
With `sqflite` or `sqlite3`, you have created your tables with `CREATE TABLE` statements.
Drift has a [Dart-based DSL](dart_api/tables.md) able to define tables
in Dart, but it can also interpret `CREATE TABLE` statements by parsing them at compile time.

Since you probably still have the `CREATE TABLE` strings available in your code, using them
is the easiest way to import your schema into drift.
For instance, you may have previously been setting up tables like this:

```dart
openDatabase(..., onCreate: (db, version) async {
await db.execute(
    'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL);');
});
```

All your `CREATE` statements can be imported into drift with a [drift file](sql_api/index.md).
To get started, add a `schema.drift` file next to your `database.dart` file with the following content:

{{ load_snippet('test','lib/snippets/setup/migrate_to_drift/schema.drift.excerpt.json') }}

Next, uncomment the `include` parameter on the `@DriftDatabase` annotation:

```dart
@DriftDatabase(include: {'schema.drift'})
```

After re-generating code with `dart run build_runner build`, drift will have generated necessary code
describing your database schema.
In addition to `CREATE TABLE` statements, drift also supports `CREATE TRIGGER`, `CREATE INDEX` and
`CREATE VIEW` statements in drift files. Other statements, like those setting pragmas, have to
be put into the `beforeOpen` section with `customStatement` invocations.

## Migrating your existing database code

Even without informing drift about the tables in your database, you can already use
low-level APIs on the database class to run queries:

- [`customSelect`](https://drift.simonbinder.eu/api/drift/databaseconnectionuser/customselect)
  replaces `rawQuery` from `package:sqflite` and `select` from `package:sqflite`.
- [`customStatement`](https://drift.simonbinder.eu/api/drift/databaseconnectionuser/customstatement)
  can be used to issue other statements for which you don't need the results.
  To run statements where you need to know the amount of affected rows afterwards, use `customUpdate`
  or `customDelete`. Finally, if you need to know the generated id for inserts, use `customInsert`.

But of course, features like auto-updating streams and type-safety are only available when
using higher-level drift APIs.
Different approaches can be used to convert existing query code to drift:

### SQL statements in drift files

In addition to the `CREATE TABLE` statements you're using to define your database,
drift files can include named SQL queries.
For instance, if you're previously used something like this:

```dart
database.rawQuery('SELECT * FROM Test WHERE value > ?', [12]);
```

Then you can copy the query into a drift file, like this:

{{ load_snippet('query','lib/snippets/setup/migrate_to_drift/schema.drift.excerpt.json') }}

After re-running the build, drift has generated a matching method exposing
the query. This method automatically returns the correct row type and has a
correctly-typed parameter for the `?` variable in SQL:

{{ load_snippet('drift-query','lib/snippets/setup/migrate_to_drift/database.dart.excerpt.json') }}

Especially for users already familiar with SQL, drift files are a very powerful
feature to structure databases.
You can of course mix definitions from drift files with tables and queries defined
in Dart if that works better.
For more information about drift files, see [their documentation page](sql_api/drift_files.md).

### Dart queries

Drift provides a query builder in Dart, which can be used to write SQL statements.
For example, the `SELECT * FROM Test WHERE value > ?` query from the previous example
can also be written like this:

{{ load_snippet('dart-query','lib/snippets/setup/migrate_to_drift/database.dart.excerpt.json') }}

Here, `watch()` is used instead of `get()` in the end to automatically turn the statement
into an auto-updating stream.

For more information about the dart_api, see [this overview](./Dart%20API/manager.md).

## Next steps

This page gave a quick overview on the steps used to migrate to existing sqlite3 databases to drift.
Drift has to offer a lot, and not every feature was highlighted in this quick guide. After completing
the initial migration, you can browse [the docs](index.md) to learn more about drift
and its features.

If you need more help with drift, or have questions on migrating, there's an active community happy to
help! A great way to ask is by [starting a discussion](https://github.com/simolus3/drift/discussions)
on the GitHub project.
