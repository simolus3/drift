---
data:
  title: "Getting started with sql"
  weight: 5
  description: Learn how to get started with the SQL version of drift, or how to migrate an existing project to drift.
template: layouts/docs/single
---

The regular [getting started guide]({{ "index.md" | pageUrl }}) explains how to get started with drift by
declaring both tables and queries in Dart. This version will focus on how to use drift with SQL instead.

## Adding the dependency
First, lets add drift to your project's `pubspec.yaml`.
At the moment, the current version of `drift` is [![Drift version](https://img.shields.io/pub/v/drift.svg)](https://pub.dev/packages/drift)
and the latest version of `drift_dev` is [![Generator version](https://img.shields.io/pub/v/drift_dev.svg)](https://pub.dev/packages/drift_dev).

{% assign versions = 'package:moor_documentation/versions.json' | readString | json_decode %}

```yaml
dependencies:
  drift: ^{{ versions.drift }}
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.0.0
  path: ^{{ versions.path }}

dev_dependencies:
  drift_dev: ^{{ versions.drift_dev }}
  build_runner: ^{{ versions.build_runner }}
```

If you're wondering why so many packages are necessary, here's a quick overview over what each package does:

- `drift`: This is the core package defining most apis
- `sqlite3_flutter_libs`: Ships the latest `sqlite3` version with your Android or iOS app. This is not required when you're _not_ using Flutter,
  but then you need to take care of including `sqlite3` yourself.
- `path_provider` and `path`: Used to find a suitable location to store the database. Maintained by the Flutter and Dart team
- `drift_dev`: This development-only dependency generates query code based on your tables. It will not be included in your final app.
- `build_runner`: Common tool for code-generation, maintained by the Dart team

{% include "partials/changed_to_ffi" %}

## Declaring tables and queries

To declare tables and queries in sql, create a file called `tables.drift`
next to your Dart files (for instance in `lib/database/tables.drift`).

You can put `CREATE TABLE` statements for your queries in there.
The following example creates two tables to model a todo-app. If you're
migrating an existing project to drift, you can just copy the `CREATE TABLE`
statements you've already written into this file.
```sql
-- this is the tables.drift file
CREATE TABLE todos (
    id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    body TEXT,
    category INT REFERENCES categories (id)
);

CREATE TABLE categories (
    id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
    description TEXT
) AS Category; -- see the explanation on "AS Category" below

/* after declaring your tables, you can put queries in here. Just
   write the name of the query, a colon (:) and the SQL: */
todosInCategory: SELECT * FROM todos WHERE category = ?;

/* Here's a more complex query: It counts the amount of entries per 
category, including those entries which aren't in any category at all. */
countEntries:     
  SELECT
    c.description,
    (SELECT COUNT(*) FROM todos WHERE category = c.id) AS amount
  FROM categories c
  UNION ALL
  SELECT null, (SELECT COUNT(*) FROM todos WHERE category IS NULL)
```

{% block "blocks/alert" title="On that AS Category" %}
Drift will generate Dart classes for your tables, and the name of those
classes is based on the table name. By default, drift just strips away
the trailing `s` from your table. That works for most cases, but in some
(like the `categories` table above), it doesn't. We'd like to have a
`Category` class (and not `Categorie`) generated, so we tell drift to
generate a different name with the `AS <name>` declaration at the end.
{% endblock %}

## Generating matching code

After you declared the tables, lets generate some Dart code to actually
run them. Drift needs to know which tables are used in a database, so we
have to write a small Dart class that drift will then read. Lets create
a file called `database.dart` next to the `tables.drift` file you wrote
in the previous step.

```dart
import 'dart:io';

import 'package:drift/drift.dart';
// These imports are only needed to open the database
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

@DriftDatabase(
  // relative import for the drift file. Drift also supports `package:`
  // imports
  include: {'tables.drift'},
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
```

To generate the `database.g.dart` file which contains the `_$AppDb`
superclass, run `flutter pub run build_runner build` on the command 
line.

## What drift generates

Let's take a look at what drift generated during the build:

- Generated data classes (`Todo` and `Category`) - these hold a single
  row from the respective table.
- Companion versions of these classes. Those are only relevant when 
  using the Dart apis of drift, you can [learn more here]({{ "writing_queries.md#inserts" | pageUrl }}).
- A `CountEntriesResult` class, it holds the result rows when running the
  `countEntries` query.
- A `_$AppDb` superclass. It takes care of creating the tables when
  the database file is first opened. It also contains typesafe methods
  for the queries declared in the `tables.drift` file:
  - a `Selectable<Todo> todosInCategory(int)` method, which runs the
    `todosInCategory` query declared above. Drift has determined that the
    type of the variable in that query is `int`, because that's the type
    of the `category` column we're comparing it to.   
    The method returns a `Selectable` to indicate that it can both be
    used as a regular query (`Selectable.get` returns a `Future<List<Todo>>`)
    or as an auto-updating stream (by using `.watch` instead of `.get()`).
  - a `Selectable<CountEntriesResult> countEntries()` method, which runs
    the other query when used.

By the way, you can also put insert, update and delete statements in
a `.drift` file - drift will generate matching code for them as well.

## Learning more

Now that you know how to use drift together with sql, here are some
further guides to help you learn more:

- The [SQL IDE]({{ "../Using SQL/sql_ide.md" | pageUrl }}) that provides feedback on sql queries right in your editor.
- [Transactions]({{ "../transactions.md" | pageUrl }})
- [Schema migrations]({{ "../Advanced Features/migrations.md" | pageUrl }})
- Writing [queries]({{ "writing_queries.md" | pageUrl }}) and
  [expressions]({{ "../Advanced Features/expressions.md" | pageUrl }}) in Dart
- A more [in-depth guide]({{ "../Using SQL/moor_files.md" | pageUrl }}) 
  on `drift` files, which explains `import` statements and the Dart-SQL interop.

{% block "blocks/alert" title="Using the database" %}
> The database class from this guide is ready to be used with your app.
  For Flutter apps, a Drift database class is typically instantiated at the top of your widget tree
  and then passed down with `provider` or `riverpod`.
  See [using the database]({{ '../faq.md#using-the-database' | pageUrl }}) for ideas on how to integrate
  Drift into your app's state management.

  The setup in this guide uses [platform channels](https://flutter.dev/docs/development/platform-integration/platform-channels),
  which are only available after running `runApp` by default.
  When using drift before your app is initialized, please call `WidgetsFlutterBinding.ensureInitialized()` before using
  the database to ensure that platform channels are ready.
{% endblock %}
