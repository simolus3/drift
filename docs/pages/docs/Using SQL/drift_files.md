---
data:
  title: "Drift files"
  weight: 1
  description: Learn everything about the new `.drift` files which can contain tables and queries

aliases:
  - /docs/using-sql/custom_tables/  # Redirect from outdated "custom tables" page which has been deleted
  - /docs/using-sql/moor_files/

template: layouts/docs/single
---

{% assign dart_snippets = "package:moor_documentation/snippets/drift_files/database.dart.excerpt.json" | readString | json_decode %}
{% assign drift_tables = "package:moor_documentation/snippets/drift_files/tables.drift.excerpt.json" | readString | json_decode %}
{% assign small = "package:moor_documentation/snippets/drift_files/small_snippets.drift.excerpt.json" | readString | json_decode %}

Drift files are a new feature that lets you write all your database code in SQL - drift will generate typesafe APIs for them.

## Getting started
To use this feature, lets create two files: `database.dart` and `tables.drift`. The Dart file only contains the minimum code
to setup the database:

{% include "blocks/snippet" snippets = dart_snippets name = "overview" %}

We can now declare tables and queries in the drift file:

{% include "blocks/snippet" snippets = drift_tables %}

After running the build runner with `flutter pub run build_runner build`,
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
[build option]({{ '../Advanced Features/builder_options.md' | pageUrl }}) is
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

## Supported column types

We use [this algorithm](https://www.sqlite.org/datatype3.html#determination_of_column_affinity)
to determine the column type based on the declared type name.

Additionally, columns that have the type name `BOOLEAN` or `DATETIME` will have
`bool` or `DateTime` as their Dart counterpart. Both will be
written as an `INTEGER` column when the table gets created.

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

{% assign nested = "package:moor_documentation/snippets/drift_files/nested.drift.excerpt.json" | readString | json_decode %}

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

At the moment, there are some limitations with this approach:

- `**` is not yet supported in compound select statements
- you can only use `table.**` if table is an actual table or a reference to it.
  In particular, it doesn't work for result sets from `WITH` clauses or table-
  valued functions.

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

Also, as `LIST()` needs a semantic rewrite of the original statement, this feature is only
supported with the `new_sql_code_generation` [build option]({{ '../Advanced Features/builder_options.md' | pageUrl }}).

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
```sql
_filterTodos: SELECT * FROM todos WHERE $predicate;
```
Drift will generate a `Selectable<Todo> _filterTodos(Expression<bool> predicate)`
method that can be used to construct dynamic filters at runtime:
```dart
Stream<List<Todo>> watchInCategory(int category) {
    return _filterTodos(todos.category.equals(category)).watch();
}
```
This lets you write a single SQL query and dynamically apply a predicate at runtime!
This feature works for

- [expressions]({{ "../Advanced Features/expressions.md" | pageUrl }}), as you've seen in the example above
- single ordering terms: `SELECT * FROM todos ORDER BY $term, id ASC`
  will generate a method taking an `OrderingTerm`.
- whole order-by clauses: `SELECT * FROM todos ORDER BY $order`
- limit clauses: `SELECT * FROM todos LIMIT $limit`
- insertables for insert statements: `INSERT INTO todos $row` generates an `Insertable<TodoEntry> row`
  parameter

When used as expression, you can also supply a default value in your query:

```sql
_filterTodos ($predicate = TRUE): SELECT * FROM todos WHERE $predicate;
```

This will make the `predicate` parameter optional in Dart. It will use the
default SQL value (here, `TRUE`) when not explicitly set.

{% block "blocks/alert" title="Using column names in Dart" color="warning" %}
If your query uses table aliases, you'll need to account for that when embedding Dart
expressions in your SQL query. Consider this for instance:

```sql
findRoutes: SELECT r.* FROM routes r
  INNER JOIN points "start" ON "start".id = r."start"
  INNER JOIN points "end" ON "end".id = r."end"
WHERE $predicate
```

If you want to filter for the `start` point in Dart, you have to use
an explicit [`alias`](https://pub.dev/documentation/drift/latest/drift/DatabaseConnectionUser/alias.html):

```dart
Future<List<Route>> routesByStart(int startPointId) {
  final start = alias(points, 'start');
  return findRoutes(start.id.equals(startPointId));
}
```

You can enable the `scoped_dart_components` [build option]({{ '../Advanced Features/builder_options.md' | pageUrl }})
and let the generator help you here.
When the option is enabled, drift would generate a `Expression<bool> Function(Routes r, Points start, Points end)` as a parameter, which
makes this a lot easier:

```dart
Future<List<Route>> routesByStart(int startPointId) {
  return findRoutes((r, start, end) => start.id.equals(startPointId));
}
```
{% endblock %}

### Type converters

You can import and use [type converters]({{ "../Advanced Features/type_converters.md" | pageUrl }})
written in Dart in a drift file. Importing a Dart file works with a regular `import` statement.
To apply a type converter on a column definition, you can use the `MAPPED BY` column constraints:
```sql
CREATE TABLE users (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  preferences TEXT MAPPED BY `const PreferenceConverter()`
);
```


More details on type converts in drift files are available
[here]({{ "../Advanced Features/type_converters.md#using-converters-in-moor" | pageUrl }}).

When using type converters, we recommend the [`apply_converters_on_variables`]({{ "../Advanced Features/builder_options.md" | pageUrl }})
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
For more general information on this feature, please check [this page]({{ '../Advanced Features/custom_row_classes.md' | pageUrl }}).

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