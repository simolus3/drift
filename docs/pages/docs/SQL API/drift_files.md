---
data:
  title: "Drift files"
  weight: 1
  description: Learn everything about the `.drift` files, a powerful tool to define your database in SQL.

aliases:
  - /docs/using-sql/custom_tables/  # Redirect from outdated "custom tables" page which has been deleted
  - /docs/using-sql/moor_files/
  - /docs/using-sql/drift_files/

template: layouts/docs/single
---

{% assign dart_snippets = "package:drift_docs/snippets/drift_files/database.dart.excerpt.json" | readString | json_decode %}
{% assign drift_tables = "package:drift_docs/snippets/drift_files/tables.drift.excerpt.json" | readString | json_decode %}
{% assign small = "package:drift_docs/snippets/drift_files/small_snippets.drift.excerpt.json" | readString | json_decode %}

{% assign newDrift = "package:drift_docs/snippets/modular/drift/example.drift.excerpt.json" | readString | json_decode %}
{% assign newDart = "package:drift_docs/snippets/modular/drift/dart_example.dart.excerpt.json" | readString | json_decode %}

Drift files are a new feature that lets you write all your database code in SQL.
But unlike raw SQL strings you might pass to simple database clients, everything in a drift file is verified
by drift's powerful SQL analyzer.
This allows you to write SQL queries safer: Drift will find mistakes in them during builds, and it will generate typesafe
Dart APIs for them so that you don't have to read back results manually.

## Getting started
To use this feature, lets create two files: `database.dart` and `tables.drift`. The Dart file only contains the minimum code
to setup the database:

{% include "blocks/snippet" snippets = dart_snippets name = "overview" %}

We can now declare tables and queries in the drift file:

{% include "blocks/snippet" snippets = drift_tables %}

After running the build runner with `dart run build_runner build`,
drift will write the `database.g.dart`
file which contains the `_$MyDb` superclass. Let's take a look at
what we got:

- Generated data classes (`Todo` and `Category`), and companion versions
  for inserts (see [Dart Interop](#dart-interop) for info). By default,
  drift strips a trailing "s" from the table name for the class. That's why
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
Inside of named queries, you can use variables just like you would expect with
sql. We support regular variables (`?`), explicitly indexed variables (`?123`)
and colon-named variables (`:id`). We don't support variables declared
with @ or $. The compiler will attempt to infer the variable's type by
looking at its context. This lets drift generate typesafe apis for your
queries, the variables will be written as parameters to your method.

When it's ambiguous, the analyzer might be unable to resolve the type of
a variable. For those scenarios, you can also denote the explicit type
of a variable:

{% include "blocks/snippet" snippets = small name = "q1" %}

In addition to the base type, you can also declare that the type is nullable:

{% include "blocks/snippet" snippets = small name = "q2" %}

Finally, you can declare that a variable should be required in Dart when using
named parameters. To do so, add a `REQUIRED` keyword:

{% include "blocks/snippet" snippets = small name = "q3" %}

Note that this only has an effect when the `named_parameters`
[build option]({{ '../Generation options/index.md' | pageUrl }}) is
enabled. Further, non-nullable variables are required by default.

### Arrays
If you want to check whether a value is in an array of values, you can
use `IN ?`. That's not valid sql, but drift will desugar that at runtime. So, for this query:

{% include "blocks/snippet" snippets = small name = "entries" %}

Drift will generate a `Selectable<Todo> entriesWithId(List<int> ids)` method.
Running `entriesWithId([1,2])` would generate `SELECT * ... id IN (?1, ?2)` and
bind the arguments accordingly. To make sure this works as expected, drift
imposes two small restrictions:

1. __No explicit variables__: `WHERE id IN ?2` will be rejected at build time.
As the variable is expanded, giving it a single index is invalid.
2. __No higher explicit index after a variable__: Running
`WHERE id IN ? OR title = ?2` will also be rejected. Expanding the
variable can clash with the explicit index, which is why drift forbids
it. Of course, `id IN ? OR title = ?` will work as expected.

## Defining tables

In `.drift` files, you can define table with a `CREATE TABLE` statement, just
like you would write it in SQL.

### Supported column types

Just like sqlite itself, we use [this algorithm](https://www.sqlite.org/datatype3.html#determination_of_column_affinity)
to determine the column type based on the declared type name.

Additionally, columns that have the type name `BOOLEAN` or `DATETIME` will have
`bool` or `DateTime` as their Dart counterpart.
Booleans are stored as `INTEGER` (either `0` or `1`). Datetimes are stored as
unix timestamps (`INTEGER`) or ISO-8601 (`TEXT`) depending on a configurable
build option.
Dart enums can automatically be stored by their index by using an `ENUM()` type
referencing the Dart enum class:

```dart
enum Status {
   none,
   running,
   stopped,
   paused
}
```

```sql
import 'status.dart';

CREATE TABLE tasks (
  id INTEGER NOT NULL PRIMARY KEY,
  status ENUM(Status)
);
```

More information on storing enums is available [in the page on type converters]({{ '../type_converters.md#using-converters-in-moor' | pageUrl }}).
Instead of using an integer mapping enums by their index, you can also store them
by their name. For this, use `ENUMNAME(...)` instead of `ENUM(...)`.

For details on all supported types, and information on how to switch between the
datetime modes, see [this section]({{ '../Dart API/tables.md#supported-column-types' | pageUrl }}).

The additional drift-specific types (`BOOLEAN`, `DATETIME`, `ENUM` and `ENUMNAME`) are also supported in `CAST`
expressions, which is helpful for views:

```sql
CREATE VIEW with_next_status AS
  SELECT id, CAST(status + 1 AS ENUM(Status)) AS status
    FROM tasks
    WHERE status < 3;
```

### Drift-specific features

To help support drift's Dart API, `CREATE TABLE` statements in drift files can
use special syntax for Dart-specific features.
Of course, drift will strip this special syntax from the `CREATE TABLE`
statement before it runs it.

- You can define a [custom row class](#existing-row-classes) for a table or
  a defined query by appending `WITH YourDartClass` to a `CREATE TABLE` statement.
- Alternatively, you may use `AS DesiredRowClassName` to change the name of the
  row class generated by drift.
- In a column definition, `MAPPED BY` can be used to [apply a converter](#type-converters)
  to that column.
- Similarly, a `JSON KEY` constraint can be used to define the key drift will
  use when serializing a row of that table to JSON.
- Finally, `AS getterName` can be used as a column constraint to override the
  generated name of that column in Dart.
  This can be useful when the default column name, inspired by the name of the
  column in SQL, conflicts with another member of the generated table class.

## Imports
You can put import statements at the top of a `drift` file:

{% include "blocks/snippet" snippets = small name = "import" %}

All tables reachable from the other file will then also be visible in
the current file and to the database that `includes` it. If you want
to declare queries on tables that were defined in another drift
file, you also need to import that file for the tables to be
visible.
Note that imports in drift file are always transitive, so in the above example
you would have all imports declared in `other.drift` available as well.
There is no `export` mechanism for drift files.

Importing Dart files into a drift file will also work - then,
all the tables declared via Dart tables can be used inside queries.
We support both relative imports and the `package:` imports you
know from Dart.

## Nested results

{% assign nested = "package:drift_docs/snippets/drift_files/nested.drift.excerpt.json" | readString | json_decode %}

Many queries fetch all columns from some table, typically by using the
`SELECT table.*` syntax. That approach can become a bit tedious when applied
over multiple tables from a join, as shown in this example:

{% include "blocks/snippet" snippets = nested name = "overview" %}

To match the returned column names while avoiding name clashes in Dart, drift
will generate a class having an `id`, `name`,  `id1`, `lat`, `long`, `lat1` and
a `long1` field.
Of course, that's not helpful at all - was `lat1` coming from `from` or `to`
again? Let's rewrite the query, this time using nested results:

{% include "blocks/snippet" snippets = nested name = "nested" %}

As you can see, we can nest a result simply by using the drift-specific
`table.**` syntax.
For this query, drift will generate the following class:
```dart
class RoutesWithNestedPointsResult {
  final int id;
  final String name;
  final Point from;
  final Point to;
  // ...
}
```

Great! This class matches our intent much better than the flat result class
from before.

These nested result columns (`**`) can appear in top-level select statements
only, they're not supported in compound select statements or subqueries yet.
However, they can refer to any result set in SQL that has been joined to the
select statement - including subqueries table-valued functions.

You might be wondering how `**` works under the hood, since it's not valid sql.
At build time, drift's generator will transform `**` into a list of all columns
from the referred table. For instance, if we had a table `foo` with an `id INT`
and a `bar TEXT` column. Then, `SELECT foo.** FROM foo` might be desugared to
`SELECT foo.id AS "nested_0.id", foo.bar AS "nested_0".bar FROM foo`.

## `LIST` subqueries

Starting from Drift version `1.4.0`, subqueries can also be selected as a full
list. Simply put the subquery in a `LIST()` function to include all rows of the
subquery in the result set.

Re-using the `coordinates` and `saved_routes` tables introduced in the example
for [nested results](#nested-results), we add a new table storing coordinates
along a route:

{% include "blocks/snippet" snippets = nested name = "route_points" %}

Now, assume we wanted to query a route with information about all points
along the way. While this requires two SQL statements, we can write this as a
single drift query that is then split into the two statements automatically:

{% include "blocks/snippet" snippets = nested name = "list" %}

This will generate a result set containing a `SavedRoute route` field along with a
`List<Point> points` list of all points along the route.

Internally, drift will split this query into two separate queries:
 - The outer `SELECT route.** FROM saved_routes route` SQL queries
 - A separate `SELECT coordinates.* FROM route_points ... ORDER BY index_on_route` query
   that is run for each row in the outer query. The `route.id` reference in the inner
   query is replaced with a variable that drift binds to the actual value in the
   outer query.

While `LIST()` subqueries are a very powerful feature, they can be costly when the outer query
has lots of rows (as the inner query is executed for each outer row).

## Dart interop
Drift files work perfectly together with drift's existing Dart API:

- you can write Dart queries for tables declared in a drift file:

{% include "blocks/snippet" snippets = dart_snippets name = "dart_interop_insert" %}

- by importing Dart files into a drift file, you can write sql queries for
  tables declared in Dart.
- generated methods for queries can be used in transactions, they work
  together with auto-updating queries, etc.

If you're using the `fromJson` and `toJson` methods in the generated
Dart classes and need to change the name of a column in json, you can
do that with the `JSON KEY` column constraints, so `id INT NOT NULL JSON KEY userId`
would generate a column serialized as "userId" in json.

### Dart components in SQL

You can make most of both SQL and Dart with "Dart Templates", which is a
Dart expression that gets inlined to a query at runtime. To use them, declare a
$-variable in a query:

{% include "blocks/snippet" snippets = newDrift name = "filterTodos" %}

Drift will generate a `Selectable<Todo>` method with a `predicate` parameter that
can be used to construct dynamic filters at runtime:

{% include "blocks/snippet" snippets = newDart name = "watchInCategory" %}

This lets you write a single SQL query and dynamically apply a predicate at runtime!
This feature works for

- [expressions]({{ "../Dart API/expressions.md" | pageUrl }}), as you've seen in the example above
- single ordering terms: `SELECT * FROM todos ORDER BY $term, id ASC`
  will generate a method taking an `OrderingTerm`.
- whole order-by clauses: `SELECT * FROM todos ORDER BY $order`
- limit clauses: `SELECT * FROM todos LIMIT $limit`
- insertables for insert statements: `INSERT INTO todos $row` generates an `Insertable<TodoEntry> row`
  parameter

When used as expression, you can also supply a default value in your query:

{% include "blocks/snippet" snippets = newDrift name = "getTodos" %}

This will make the `predicate` parameter optional in Dart. It will use the
default SQL value (here, `TRUE`) when not explicitly set.

### Type converters

You can import and use [type converters]({{ "../type_converters.md" | pageUrl }})
written in Dart in a drift file. Importing a Dart file works with a regular `import` statement.
To apply a type converter on a column definition, you can use the `MAPPED BY` column constraints:

```sql
CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  preferences TEXT MAPPED BY `const PreferenceConverter()`
);
```

Queries or views that reference a table-column with a type converter will also inherit that
converter. In addition, both queries and views can specify a type converter to use for a
specific column as well:

```sql
CREATE VIEW my_view AS SELECT 'foo' MAPPED BY `const PreferenceConverter()`

SELECT
  id,
  json_extract(preferences, '$.settings') MAPPED BY `const PreferenceConverter()`
FROM users;
```

More details on type converts in drift files are available
[here]({{ "../type_converters.md#using-converters-in-moor" | pageUrl }}).

When using type converters, we recommend the [`apply_converters_on_variables`]({{ "../Generation options/index.md" | pageUrl }})
build option. This will also apply the converter from Dart to SQL, for instance if used on variables: `SELECT * FROM users WHERE preferences = ?`.
With that option, the variable will be inferred to `Preferences` instead of `String`.


### Existing row classes

You can use custom row classes instead of having drift generate one for you.
For instance, let's say you had a Dart class defined as

```dart
class User {
 final int id;
 final String name;

 User(this.id, this.name);
}
```

Then, you can instruct drift to use that class as a row class as follows:

```sql
import 'row_class.dart'; --import for where the row class is defined

CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
) WITH User; -- This tells drift to use the existing Dart class
```

When using custom row classes defined in another Dart file, you also need to import that file into the file where you define
the database.
For more general information on this feature, please check [this page]({{ '../custom_row_classes.md' | pageUrl }}).

Custom row classes can be applied to `SELECT` queries defined a `.drift` file. To use a custom row class, the `WITH` syntax
can be added after the name of the query.

For instance, let's say we expand the existing Dart code in `row_class.dart` by adding another class:

```dart
class UserWithFriends {
  final User user;
  final List<User> friends;

  UserWithFriends(this.user, {this.friends = const []});
}
```

Now, we can add a corresponding query using the new class for its rows:

```sql
-- table to demonstrate a more complex select query below.
-- also, remember to add the import for `UserWithFriends` to your drift file.
CREATE TABLE friends (
  user_a INTEGER NOT NULL REFERENCES users(id),
  user_b INTEGER NOT NULL REFERENCES users(id),
  PRIMARY KEY (user_a, user_b)
);

allFriendsOf WITH UserWithFriends: SELECT users.**, LIST(
  SELECT * FROM users a INNER JOIN friends ON user_a = a.id WHERE user_b = users.id
  UNION ALL
  SELECT * FROM users b INNER JOIN friends ON user_b = b.id WHERE user_a = users.id
)  AS friends FROM users WHERE id = :id;
```

The `WITH UserWithFriends` syntax will make drift consider the `UserWithFriends` class.
For every field in the constructor, drift will check the column from the query and
verify that it has a compatible type.
Internally, drift will then generate query code to map the row to an instance of the
`UserWithFriends` class.

For a more complete overview of using custom row classes for queries, see
[the section for queries]({{ '../custom_row_classes.md#queries' | pageUrl }}).

### Dart documentation comments

Comments added before columns in a drift file are added as Dart documentation comments
in the generated row class:

```sql
CREATE TABLE friends (
  -- The user original sending the friendship request
  user_a INTEGER NOT NULL REFERENCES users(id),
  -- The user accepting the friendship request from [userA].
  user_b INTEGER NOT NULL REFERENCES users(id),
  PRIMARY KEY (user_a, user_b)
);
```

The generated `userA` and `userB` field in the `Friend` class generated by drift will
have these comments as documentation comments.

## Result class names

For most queries, drift generates a new class to hold the result. This class is named after the query
with a `Result` suffix, e.g. a `myQuery` query would get a `MyQueryResult` class.

You can change the name of a result class like this:

```sql
routesWithNestedPoints AS FullRoute: SELECT r.id, -- ...
```

This way, multiple queries can also share a single result class. As long as they have an identical result set,
you can assign the same custom name to them and drift will only generate one class.

For queries that select all columns from a table and nothing more, drift won't generate a new class
and instead re-use the dataclass that it generates either way.
Similarly, for queries with only one column, drift will just return that column directly instead of
wrapping it in a result class.
It's not possible to override this behavior at the moment, so you can't customize the result class
name of a query if it has a matching table or only has one column.

## Supported statements

At the moment, the following statements can appear in a `.drift` file.

- `import 'other.drift'`: Import all tables and queries declared in the other file
   into the current file.
- DDL statements: You can put `CREATE TABLE`, `CREATE VIEW`, `CREATE INDEX` and `CREATE TRIGGER` statements
  into drift files.
- Query statements: We support `INSERT`, `SELECT`, `UPDATE` and `DELETE` statements.

All imports must come before DDL statements, and those must come before named queries.

If you need support for another statement, or if drift rejects a query you think is valid, please
create an issue!