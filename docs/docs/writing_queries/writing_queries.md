---
layout: guide
title: Writing queries
nav_order: 2
has_children: true
permalink: /queries/
---

__Note__: This assumes that you already have your database class ready. 
Follow the [instructions][getting-started] over here on how to do that.

# Writing queries
The examples here use the tables defined [here][getting-started].
For each table you've specified in the `@UseMoor` annotation on your database class,
a corresponding getter for a table will be generated. That getter can be used to
run statements:
```dart
// inside the database class, the `todos` getter has been created by moor.

// loads all todo entries
Future<List<Todo>> get allTodoEntries => select(todos).get();

// watches all todo entries in a given category. The stream will automatically
// emit new items whenever the underlying data changes.
Stream<List<TodoEntry>> watchEntriesInCategory(Category c) {
  return (select(todos)..where((t) => t.category.equals(c.id))).watch();
}
```
## Select statements
You can create `select` statements by starting them with `select(tableName)`, where the 
table name
is a field generated for you by moor. Each table used in a database will have a matching field
to run queries against. Any query can be run once with `get()` or be turned into an auto-updating
stream using `watch()`.
### Where
You can apply filters to a query by calling `where()`. The where method takes a function that
should map the given table to an `Expression` of boolean. A common way to create such expression
is by using `equals` on expressions. Integer columns can also be compared with `isBiggerThan`
and `isSmallerThan`. You can compose expressions using `and(a, b), or(a, b)` and `not(a)`.
### Limit
You can limit the amount of results returned by calling `limit` on queries. The method accepts
the amount of rows to return and an optional offset.
### Ordering
You can use the `orderBy` method on the select statement. It expects a list of functions that extract the individual
ordering terms from the table.
```dart
Future<List<TodoEntry>> sortEntriesAlphabetically() {
  return (select(todos)..orderBy([(t) => OrderingTerm(expression: t.title)])).get();
}
```
You can also reverse the order by setting the `mode` property of the `OrderingTerm` to
`OrderingMode.desc`.
## Updates and deletes
You can use the generated classes to update individual fields of any row:
```dart
Future moveImportantTasksIntoCategory(Category target) {
  // for updates, we use the "companion" version of a generated class. This wraps the
  // fields in a "Value" type which can be set to be absent using "Value.absent()". This
  // allows us to separate between "SET category = NULL" (`category: Value(null)`) and not
  // updating the category at all: `category: Value.absent()`.
  return (update(todos)
      ..where((t) => t.title.like('%Important%'))
    ).write(TodosCompanion(
      category: Value(target.id),
    ),
  );
}

Future update(TodoEntry entry) {
  // using replace will update all fields from the entry that are not marked as a primary key.
  // it will also make sure that only the entry with the same primary key will be updated.
  // Here, this means that the row that has the same id as entry will be updated to reflect
  // the entry's title, content and category. As it set's its where clause automatically, it
  // can not be used together with where.
  return update(todos).replace(entry);
}

Future feelingLazy() {
  // delete the oldest nine tasks
  return (delete(todos)..where((t) => t.id.isSmallerThanValue(10))).go();
}
```
__⚠️ Caution:__ If you don't explicitly add a `where` clause on updates or deletes, 
the statement will affect all rows in the table!

## Inserts
You can very easily insert any valid object into tables:
```dart
// returns the generated id
Future<int> addTodoEntry(TodosCompanion entry) {
  return into(todos).insert(entry);
}
```
All row classes generated will have a constructor that can be used to create objects:
```dart
addTodoEntry(
  Todo(
    title: 'Important task',
    content: 'Refactor persistence code',
  ),
);
```
If a column is nullable or has a default value (this includes auto-increments), the field
can be omitted. All other fields must be set and non-null. The `insert` method will throw
otherwise.

[getting-started]: {{ site.common_links.getting_started | absolute_url }}