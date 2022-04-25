---
data:
  title: "Advanced queries in Dart"
  weight: 1
  description: Use sql joins or custom expressions from the Dart api
aliases:
 - queries/joins/
template: layouts/docs/single
---

## Joins

Drift supports sql joins to write queries that operate on more than one table. To use that feature, start
a select regular select statement with `select(table)` and then add a list of joins using `.join()`. For
inner and left outer joins, a `ON` expression needs to be specified. Here's an example using the tables
defined in the [example]({{ "../Getting started/index.md" | pageUrl }}).

```dart
// we define a data class to contain both a todo entry and the associated category
class EntryWithCategory {
  EntryWithCategory(this.entry, this.category);

  final TodoEntry entry;
  final Category category;
}

// in the database class, we can then load the category for each entry
Stream<List<EntryWithCategory>> entriesWithCategory() {
  final query = select(todos).join([
    leftOuterJoin(categories, categories.id.equalsExp(todos.category)),
  ]);

  // see next section on how to parse the result
}
```

## Parsing results

Calling `get()` or `watch` on a select statement with join returns a `Future` or `Stream` of
`List<TypedResult>`, respectively. Each `TypedResult` represents a row from which data can be
read. It contains a `rawData` getter to obtain the raw columns. But more importantly, the
`readTable` method can be used to read a data class from a table.

In the example query above, we can read the todo entry and the category from each row like this:
```dart
return query.watch().map((rows) {
  return rows.map((row) {
    return EntryWithCategory(
      row.readTable(todos),
      row.readTableOrNull(categories),
    );
  }).toList();
});
```

_Note_: `readTable` will throw an `ArgumentError` when a table is not present in the row. For instance,
todo entries might not be in any category. To account for that, we use `row.readTableOrNull` to load
categories.

## Custom columns

Select statements aren't limited to columns from tables. You can also include more complex expressions in the
query. For each row in the result, those expressions will be evaluated by the database engine.

```dart
class EntryWithImportance {
  final TodoEntry entry;
  final bool important;

  EntryWithImportance(this.entry, this.important);
}

Future<List<EntryWithImportance>> loadEntries() {
  // assume that an entry is important if it has the string "important" somewhere in its content
  final isImportant = todos.content.like('%important%');

  return select(todos).addColumns([isImportant]).map((row) {
    final entry = row.readTable(todos);
    final entryIsImportant = row.read(isImportant);

    return EntryWithImportance(entry, entryIsImportant);
  }).get();
}
```

Note that the `like` check is _not_ performed in Dart - it's sent to the underlying database engine which
can efficiently compute it for all rows.

## Aliases
Sometimes, a query references a table more than once. Consider the following example to store saved routes for a
navigation system:
```dart
class GeoPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get latitude => text()();
  TextColumn get longitude => text()();
}

class Routes extends Table {

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  // contains the id for the start and destination geopoint.
  IntColumn get start => integer()();
  IntColumn get destination => integer()();
}
```

Now, let's say we wanted to also load the start and destination `GeoPoint` object for each route. We'd have to use
a join on the `geo-points` table twice: For the start and destination point. To express that in a query, aliases
can be used:
```dart
class RouteWithPoints {
  final Route route;
  final GeoPoint start;
  final GeoPoint destination;

  RouteWithPoints({this.route, this.start, this.destination});
}

// inside the database class:
Future<List<RouteWithPoints>> loadRoutes() async {
  // create aliases for the geoPoints table so that we can reference it twice
  final start = alias(geoPoints, 's');
  final destination = alias(geoPoints, 'd');

  final rows = await select(routes).join([
    innerJoin(start, start.id.equalsExp(routes.start)),
    innerJoin(destination, destination.id.equalsExp(routes.destination)),
  ]).get();

  return rows.map((resultRow) {
    return RouteWithPoints(
      route: resultRow.readTable(routes),
      start: resultRow.readTable(start),
      destination: resultRow.readTable(destination),
    );
  }).toList();
}
```
The generated statement then looks like this:
```sql
SELECT
    routes.id, routes.name, routes.start, routes.destination,
    s.id, s.name, s.latitude, s.longitude,
    d.id, d.name, d.latitude, d.longitude
FROM routes
    INNER JOIN geo_points s ON s.id = routes.start
    INNER JOIN geo_points d ON d.id = routes.destination
```

## `ORDER BY` and `WHERE` on joins

Similar to queries on a single table, `orderBy` and `where` can be used on joins too.
The initial example from above is expanded to only include todo entries with a specified
filter and to order results based on the category's id:

```dart
Stream<List<EntryWithCategory>> entriesWithCategory(String entryFilter) {
  final query = select(todos).join([
    leftOuterJoin(categories, categories.id.equalsExp(todos.category)),
  ]);
  query.where(todos.content.like(entryFilter));
  query.orderBy([OrderingTerm.asc(categories.id)]);
  // ...
}
```

As a join can have more than one table, all tables in `where` and `orderBy` have to
be specified directly (unlike the callback on single-table queries that gets called
with the right table by default).

## Group by

{% assign snippets = 'package:moor_documentation/snippets/queries.dart.excerpt.json' | readString | json_decode %}

Sometimes, you need to run queries that _aggregate_ data, meaning that data you're interested in
comes from multiple rows. Common questions include

- how many todo entries are in each category?
- how many entries did a user complete each month?
- what's the average length of a todo entry?

What these queries have in common is that data from multiple rows needs to be combined into a single
row. In sql, this can be achieved with "aggregate functions", for which drift has
[builtin support]({{ "expressions.md#aggregate" | pageUrl }}).

_Additional info_: A good tutorial for group by in sql is available [here](https://www.sqlitetutorial.net/sqlite-group-by/).

To write a query that answers the first question for us, we can use the `count` function.
We're going to select all categories and join each todo entry for each category. What's special is that we set
`useColumns: false` on the join. We do that because we're not interested in the columns of the todo item.
We only care about how many there are. By default, drift would attempt to read each todo item when it appears
in a join.

{% include "blocks/snippet" snippets = snippets name = 'countTodosInCategories' %}

To find the average length of a todo entry, we use `avg`. In this case, we don't even have to use
a `join` since all the data comes from a single table (todos).
That's a problem though - in the join, we used `useColumns: false` because we weren't interested
in the columns of each todo item. Here we don't care about an individual item either, but there's
no join where we could set that flag.
Drift provides a special method for this case - instead of using `select`, we use `selectOnly`.
The "only" means that drift will only report columns we added via "addColumns". In a regular select,
all columns from the table would be selected, which is what you'd usually need.

{% include "blocks/snippet" snippets = snippets name = 'averageItemLength' %}
