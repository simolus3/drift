---
data:
  title: "Writing queries"
  linkTitle: "Writing queries"
  description: Learn how to write database queries in pure Dart with moor
  weight: 100
aliases:
 - /queries/
template: layouts/docs/single
---

{% block "blocks/pageinfo" %}
__Note__: This assumes that you've already completed [the setup]({{ "index.md" | pageUrl }}).
{% endblock %}

For each table you've specified in the `@UseMoor` annotation on your database class,
a corresponding getter for a table will be generated. That getter can be used to
run statements:
```dart
// inside the database class, the `todos` getter has been created by moor.
@UseMoor(tables: [Todos, Categories])
class MyDatabase extends _$MyDatabase {  

  // the schemaVersion getter and the constructor from the previous page
  // have been omitted.
  
  // loads all todo entries
  Future<List<Todo>> get allTodoEntries => select(todos).get();

  // watches all todo entries in a given category. The stream will automatically
  // emit new items whenever the underlying data changes.
  Stream<List<Todo>> watchEntriesInCategory(Category c) {
    return (select(todos)..where((t) => t.category.equals(c.id))).watch();
  }
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
and `isSmallerThan`. You can compose expressions using `a & b, a | b` and `a.not()`. For more
details on expressions, see [this guide]({{ "../Advanced Features/expressions.md" | pageUrl }}).

### Limit
You can limit the amount of results returned by calling `limit` on queries. The method accepts
the amount of rows to return and an optional offset.

```dart
Future<List<Todo>> limitTodos(int limit, {int offset}) {
  return (select(todos)..limit(limit, offset: offset)).get();
}
```

### Ordering
You can use the `orderBy` method on the select statement. It expects a list of functions that extract the individual
ordering terms from the table. You can use any expression as an ordering term - for more details, see
[this guide]({{ "../Advanced Features/expressions.md" | pageUrl }}).

```dart
Future<List<Todo>> sortEntriesAlphabetically() {
  return (select(todos)..orderBy([(t) => OrderingTerm(expression: t.title)])).get();
}
```
You can also reverse the order by setting the `mode` property of the `OrderingTerm` to
`OrderingMode.desc`.

### Single values
If you know a query is never going to return more than one row, wrapping the result in a `List`
can be tedious. Moor lets you work around that with `getSingle` and `watchSingle`:
```dart
Stream<Todo> entryById(int id) {
  return (select(todos)..where((t) => t.id.equals(id))).watchSingle();
}
```
If an entry with the provided id exists, it will be sent to the stream. Otherwise,
`null` will be added to stream. If a query used with `watchSingle` ever returns
more than one entry (which is impossible in this case), an error will be added
instead.

### Mapping
Before calling `watch` or `get` (or the single variants), you can use `map` to transform
the result. 
```dart
Stream<List<String>> contentWithLongTitles() {
  final query = select(todos)
    ..where((t) => t.title.length.isBiggerOrEqualValue(16));

  return query
    .map((row) => row.content)
    .watch();
}
```

### Deferring get vs watch
If you want to make your query consumable as either a `Future` or a `Stream`,
you can refine your return type using one of the `Selectable` abstract base classes;
```dart
// Exposes `get` and `watch`
MultiSelectable<Todo> pageOfTodos(int page, {int pageSize = 10}) {
  return select(todos)..limit(pageSize, offset: page - 1);
}

// Exposes `getSingle` and `watchSingle`
SingleSelectable<Todo> entryById(int id) =>
  select(todos)..where((t) => t.id.equals(id));

// Exposes `getSingleOrNull` and `watchSingleOrNull`
SingleOrNullSelectable<Todo> entryFromExternalLink(int id) =>
  select(todos)..where((t) => t.id.equals(id));
```
These base classes don't have query-building or `map` methods, signaling to the consumer
that they are complete results.

If you need more complex queries with joins or custom columns, see [this site]({{ "../Advanced Features/joins.md" | pageUrl }}).

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

Future update(Todo entry) {
  // using replace will update all fields from the entry that are not marked as a primary key.
  // it will also make sure that only the entry with the same primary key will be updated.
  // Here, this means that the row that has the same id as entry will be updated to reflect
  // the entry's title, content and category. As its where clause is set automatically, it
  // cannot be used together with where.
  return update(todos).replace(entry);
}

Future feelingLazy() {
  // delete the oldest nine tasks
  return (delete(todos)..where((t) => t.id.isSmallerThanValue(10))).go();
}
```
__⚠️ Caution:__ If you don't explicitly add a `where` clause on updates or deletes, 
the statement will affect all rows in the table!

{% block "blocks/alert"  title="Entries, companions - why do we need all of this?" %}
You might have noticed that we used a `TodosCompanion` for the first update instead of
just passing a `Todo`. Moor generates the `Todo` class (also called _data
class_ for the table) to hold a __full__ row with all its data. For _partial_ data,
prefer to use companions. In the example above, we only set the the `category` column,
so we used a companion. 
Why is that necessary? If a field was set to `null`, we wouldn't know whether we need 
to set that column back to null in the database or if we should just leave it unchanged.
Fields in the companions have a special `Value.absent()` state which makes this explicit.

Companions also have a special constructor for inserts - all columns which don't have
a default value and aren't nullable are marked `@required` on that constructor. This makes
companions easier to use for inserts because you know which fields to set.
{% endblock %}

## Inserts
You can very easily insert any valid object into tables. As some values can be absent
(like default values that we don't have to set explicitly), we again use the 
companion version.
```dart
// returns the generated id
Future<int> addTodo(TodosCompanion entry) {
  return into(todos).insert(entry);
}
```
All row classes generated will have a constructor that can be used to create objects:
```dart
addTodo(
  TodosCompanion(
    title: Value('Important task'),
    content: Value('Refactor persistence code'),
  ),
);
```
If a column is nullable or has a default value (this includes auto-increments), the field
can be omitted. All other fields must be set and non-null. The `insert` method will throw
otherwise.

Multiple insert statements can be run efficiently by using a batch. To do that, you can
use the `insertAll` method inside a `batch`:
```dart
Future<void> insertMultipleEntries() async{
  await batch((batch) {
    // functions in a batch don't have to be awaited - just
    // await the whole batch afterwards.
    batch.insertAll(todos, [
      TodosCompanion.insert(
        title: 'First entry',
        content: 'My content',
      ),
      TodosCompanion.insert(
        title: 'Another entry',
        content: 'More content',
        // columns that aren't required for inserts are still wrapped in a Value:
        category: Value(3),
      ),
      // ...
    ]);
  });
}
```

### Upserts

Upserts are a feature from newer sqlite3 versions that allows an insert to 
behave like an update if a conflicting row already exists.

This allows us to create or override an existing row when its primary key is
part of its data:

```dart
class Users extends Table {
  TextColumn get email => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {email};
}

Future<void> createOrUpdateUser(User user) {
  return into(users).insertOnConflictUpdate(user);
}
```

When calling `createOrUpdateUser()` with an email address that already exists, 
that user's name will be updated. Otherwise, a new user will be inserted into
the database.

Inserts can also be used with more advanced queries. For instance, let's say 
we're building a dictionary and want to keep track of how many times we 
encountered a word. A table for that might look like

```dart
class Words extends Table {
  TextColumn get word => text()();
  IntColumn get usages => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {word};
}
```

By using a custom upserts, we can insert a new word or increment its `usages`
counter if it already exists:

```dart
Future<void> trackWord(String word) {
  return into(words).insert(
    WordsCompanion.insert(word: word),
    onConflict: DoUpdate((old) => WordsCompanion.custom(usages: old.usages + Constant(1))),
  );
}
```

{% block "blocks/alert" title="Unique constraints and conflict targets" %}
> Both `insertOnConflictUpdate` and `onConflict: DoUpdate` use an `DO UPDATE`
  upsert in sql. This requires us to provide a so-called "conflict target", a
  set of columns to check for uniqueness violations. By default, moor will use
  the table's primary key as conflict target. That works in most cases, but if
  you have custom `UNIQUE` constraints on some columns, you'll need to use
  the `target` parameter on `DoUpdate` in Dart to include those columns.
{% endblock %}

Note that this requires a fairly recent sqlite3 version (3.24.0) that might not
be available on older Android devices when using `moor_flutter`. `moor_ffi`
includes the latest sqlite on Android, so consider using it if you want to
support upserts.
