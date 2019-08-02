---
title: "Joins"
weight: 1
description: >
  Use joins to write queries that read from more than one table
aliases:
 - /queries/joins
---

Moor supports sql joins to write queries that operate on more than one table. To use that feature, start
a select regular select statement with `select(table)` and then add a list of joins using `.join()`. For
inner and left outer joins, a `ON` expression needs to be specified. Here's an example using the tables
defined in the [example]({{< ref "/docs/Getting Started/_index.md" >}}).

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
`List<TypedResult>` respectively. Each `TypedResult` represents a row from which data can be 
read. It contains a `rawData` getter to obtain the raw columns. But more importantly, the
`readTable` method can be used to read a data class from a table.

In the example query above, we can read the todo entry and the category from each row like this:
```dart
return query.watch().map((rows) {
  return rows.map((row) {
    return EntryWithCategory(
      row.readTable(todos),
      row.readTable(categories),
    );
  }).toList();
});
```

_Note_: `readTable` returns `null` when an entity is not present in the row. For instance, todo entries
might not be in any category. If we a row without a category, `row.readTable(categories)` would return `null`.
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