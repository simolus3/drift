---
title: "Moor files"
weight: 1
description: Learn everything about the new `.moor` files which can contain tables and queries

aliases:
  - /docs/using-sql/custom_tables/  # Redirect from outdated "custom tables" page which has been deleted
---

Moor files are a new feature that lets you write all your database code in SQL - moor will generate typesafe APIs for them.

## Getting started
To use this feature, lets create two files: `database.dart` and `tables.moor`. The Dart file only contains the minimum code
to setup the database:
```dart
import 'package:moor_flutter/moor_flutter.dart';

part 'database.g.dart';

@UseMoor(
  include: {'tables.moor'},
)
class MoorDb extends _$MoorDb {
  MoorDb() : super(FlutterQueryExecutor.inDatabaseFolder('app.db'));

  @override
  int get schemaVersion => 1;
}
```

We can now declare tables and queries in the moor file:
```sql
CREATE TABLE todos (
    id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category INTEGER REFERENCES categories(id)
);

CREATE TABLE categories (
    id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
    description TEXT NOT NULL
) AS Category; -- the AS xyz after the table defines the data class name

-- we can put named sql queries in here as well:
createEntry: INSERT INTO todos (title, content) VALUES (:title, :content);
deleteById: DELETE FROM todos WHERE id = :id;
watchAllTodos: SELECT * FROM todos;
```

After running the build runner with `flutter pub run build_runner build`,
moor will write the `database.g.dart`
file which contains the `_$MoorDb` superclass. Let's take a look at
what we got:

- Generated data classes (`Todo` and `Category`), and companion versions
  for inserts (see [Dart Interop](#dart-interop) for info). By default,
  moor strips a trailing "s" from the table name for the class. That's why 
  we used `AS Category` on the second table - it would have been called
  `Categorie` otherwise.
- Methods to run the queries:
  - a `Future<int> createEntry(String title, String content)` method. It
    creates a new todo entry with the provided data and returns the id of
    the entry created.
  - `Future<int> deleteById(int id)`: Deletes a todo entry by its id, and
    returns the amount of rows affected.
  - `Selectable<AllTodosResult> allTodos()`. It can be used to get, or
    watch, all todo entries. It can be used with `allTodos().get()` and
    `allTodos().watch()`.
- Classes for select statements that don't match a table. In the example
  above, thats the `AllTodosResult` class, which contains all fields from
  `todos` and the description of the associated category.

## Variables
We support regular variables (`?`), explictly indexed variables (`?123`)
and colon-named variables (`:id`). We don't support variables declared
with @ or $. The compiler will attempt to infer the variable's type by
looking at its context. This lets moor generate typesafe apis for your
queries, the variables will be written as parameters to your method.

### Arrays
If you want to check whether a value is in an array of values, you can
use `IN ?`. That's not valid sql, but moor will desugar that at runtime. So, for this query:
```sql
entriesWithId: SELECT * FROM todos WHERE id IN ?;
```
Moor will generate a `Selectable<Todo> entriesWithId(List<int> ids)` 
method (`entriesWithId([1,2])` would run `SELECT * ... id IN (?1, ?2)`
and bind the arguments accordingly). To support this, we only have two
restrictions:

1. __No explicit variables__: Running `WHERE id IN ?2` will be rejected
at build time. As the variable is expanded, giving it a single index is
invalid.
2. __No higher explicit index after a variable__: Running 
`WHERE id IN ? OR title = ?2` will also be rejected. Expanding the 
variable can clash with the explicit index, which is why moor forbids
it. Of course, `id IN ? OR title = ?` will work as expected.

## Imports
{{% alert title="Limited support" %}}
> Importing a moor file from another moor file will work as expected. 
  Unfortunately, importing a Dart file from moor does not work in all
  scenarios. Please upvote [this issue](https://github.com/dart-lang/build/issues/493)
  on the build package to help solve this.
{{% /alert %}}

You can put import statements at the top of a `moor` file:
```sql
import 'other.moor'; -- single quotes are required for imports
```
All tables reachable from the other file will then also be visible in
the current file and to the database that `includes` it. Importing
Dart files into a moor file will also work - then, all the tables
declared via Dart tables can be used inside queries.
We support both relative imports and the `package:` imports you
know from Dart.

## Dart interop
Moor files work perfectly together with moor's existing Dart API:

- you can write Dart queries for tables declared in a moor file:
```dart
Future<void> insert(TodosCompanion companion) async {
      await into(todos).insert(companion);
}
```
- by importing Dart files into a moor file, you can write sql queries for
  tables declared in Dart.
- generated methods for queries can be used in transactions, they work 
  together with auto-updating queries, etc.

### Dart components in SQL

You can make most of both SQL and Dart with "Dart Templates", which is a
Dart expression that gets inlined to a query at runtime. To use them, declare a 
$-variable in a query:
```sql
_filterTodos: SELECT * FROM todos WHERE $predicate;
```
Moor will generate a `Selectable<Todo> _filterTodos(Expression<bool, BoolType> predicate)` method which can be used to construct dynamic
filters at runtime:
```dart
Stream<List<Todo>> watchInCategory(int category) {
    return _filterTodos(todos.category.equals(category)).watch();
}
```
This lets you write a single SQL query and dynamically apply a predicate at runtime!
This feature also works for

- expressions
- single ordering terms: `SELECT * FROM todos ORDER BY $term, id ASC`
  will generate a method taking an `OrderingTerm`.
- whole order-by clauses: `SELECT * FROM todos ORDER BY $order`
- limit clauses: `SELECT * FROM todos LIMIT $limit`

## Supported statements
At the moment, the following statements can appear in a `.moor` file.

- `import 'other.moor'`: Import all tables and queries declared in the other file
   into the current file.
- DDL statements (`CREATE TABLE`): Declares a table. We don't currently support indices and views,
   [#162](https://github.com/simolus3/moor/issues/162) tracks support for that.
- Query statements: We support `INSERT`, `SELECT`, `UPDATE` and `DELETE` statements.

All imports must come before DDL statements, and those must come before the named queries.

If you need support for another statement, or if moor rejects a query you think is valid, please
create an issue!