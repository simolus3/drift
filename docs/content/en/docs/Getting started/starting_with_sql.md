---
title: "Getting started with sql"
weight: 5
description: Learn how to get started with the SQL version of moor, or how to migrate an existing project to moor.
---

The regular [getting started guide]({{< relref "_index.md" >}}) explains how to get started with moor by
declaring both tables and queries in Dart. This version will focus on how to use moor with SQL instead.

## Adding the dependency
First, lets add moor to your project's `pubspec.yaml`.
At the moment, the current version of `moor_flutter` is [![Flutter version](https://img.shields.io/pub/v/moor_flutter.svg)](https://pub.dartlang.org/packages/moor_flutter) and the current version of `moor_generator` is [![Generator version](https://img.shields.io/pub/v/moor_generator.svg)](https://pub.dartlang.org/packages/moor_generator)

```yaml
dependencies:
  moor_flutter: # use the latest version

dev_dependencies:
  moor_generator: # use the latest version
  build_runner: 
```

The `moor_flutter` package will execute sql at runtime, while the
`moor_generator` will generate typesafe Dart based on your SQL queries.

## Declaring tables and queries

To declare tables and queries in sql, create a file called `tables.moor`
next to your Dart files (for instance in `lib/database/tables.moor`).

You can put the `CREATE TABLE` statements for your queries in there.
The following example creates two tables to model a todo-app. If you're
migrating an existing project to moor, you would put the `CREATE TABLE`
for your tables in there.
```sql
-- this is the tables.moor file
CREATE TABLE todos (
    id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    body TEXT,
    category INT REFERENCES categories (id)
);

CREATE TABLE categories (
    id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
    description TEXT,
) AS Category; -- see the explanation on "AS Category" below

/* after declaring your tables, you can put queries in here. Just
   write the name of the query, a colon (:) and the SQL: */
todosInCategory: SELECT * FROM todos WHERE category = ?;

/* Here's a more complex query: It counts the amount of entries per 
category, including those entries which aren't in any category at all. */
countEntries:     
  SELECT
    c.desc,
    (SELECT COUNT(*) FROM todos WHERE category = c.id) AS amount
  FROM categories c
  UNION ALL
  SELECT null, (SELECT COUNT(*) FROM todos WHERE category IS NULL)
```

{{% alert title="On that AS Category" %}}
Moor will generate Dart classes for your tables, and the name of those
classes is based on the table name. By default, moor just strips away
the trailing `s` from your table. That works for most cases, but in some
(like the `categories` table above), it doesn't. We'd like to have a
`Category` class (and not `Categorie`) generated, so we tell moor to
generate a different name with the `AS <name>` declaration at the end.
{{% /alert %}}

## Generating matching code

After you declared the tables, lets generate some Dart code to actually
run them. Moor needs to know which tables are used in a database, so we
have to write a small Dart class that moor will then read. Lets create
a file called `database.dart` next to the `tables.moor` file you wrote
in the previous step.

```dart
import 'package:moor_flutter/moor_flutter.dart';

part 'database.g.dart';

@UseMoor(
  include: {'tables.moor'},
)
class AppDb extends _$AppDb {
  AppDb() : super(FlutterQueryExecutor.inDatabaseFolder('app.db'));

  @override
  int get schemaVersion => 1;
}
```

To generate the `database.g.dart` file which contains the `_$AppDb`
superclass, run `flutter pub run build_runner build` on the command 
line.

## What moor generates

Let's take a look at what moor generated during the build:

- Generated data classes (`Todo` and `Category`) - these hold a single
  row from the respective table.
- Companion versions of these classes. Those are only relevant when 
  using the Dart apis of moor, you can [learn more here]({{< relref "writing_queries.md#inserts" >}}).
- A `CountEntriesResult` class, it holds the result rows when running the
  `countEntries` query.
- A `_$AppDb` superclass. It takes care of creating the tables when
  the database file is first opened. It also contains typesafe methods
  for the queries declared in the `tables.moor` file:
  - a `Selectable<Todo> todosInCategory(int)` method, which runs the
    `todosInCategory` query declared above. Moor has determined that the
    type of the variable in that query is `int`, because that's the type
    of the `category` column we're comparing it to.   
    The method returns a `Selectable` to indicate that it can both be
    used as a regular query (`Selectable.get` returns a `Future<List<Todo>>`)
    or as an auto-updating stream (by using `.watch` instead of `.get()`).
  - a `Selectable<CountEntriesResult> countEntries()` method, which runs
    the other query when used.

By the way, you can also put insert, update and delete statements in
a `.moor` file - moor will generate matching code for them as well.

## Learning more

Know that you know how to use moor together with sql, here are some
further guides to help you learn more:

- The [SQL IDE]({{< relref "../Using SQL/sql_ide.md" >}}) that provides feedback on sql queries right in your editor.
- [Transactions]({{< relref "../transactions.md" >}})
- [Schema migrations]({{< relref "../Advanced Features/migrations.md" >}})
- Writing [queries]({{< relref "writing_queries.md" >}}) and
  [expressions]({{< relref "expressions.md" >}}) in Dart
- A more [in-depth guide]({{< relref "../Using SQL/moor_files.md" >}}) 
  on `moor` files, which explains `import` statements and the Dart-SQL interop.