---
data:
  title: "Writes (update, insert, delete)"
  description: "Select rows or invidiual columns from tables in Dart"
  weight: 3
template: layouts/docs/single
---

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

Future updateTodo(Todo entry) {
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
just passing a `Todo`. Drift generates the `Todo` class (also called _data
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

Batches are similar to transactions in the sense that all updates are happening atomically,
but they enable further optimizations to avoid preparing the same SQL statement twice.
This makes them suitable for bulk insert or update operations.

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

Future<int> createOrUpdateUser(User user) {
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
Both `insertOnConflictUpdate` and `onConflict: DoUpdate` use an `DO UPDATE`
upsert in sql. This requires us to provide a so-called "conflict target", a
set of columns to check for uniqueness violations. By default, drift will use
the table's primary key as conflict target. That works in most cases, but if
you have custom `UNIQUE` constraints on some columns, you'll need to use
the `target` parameter on `DoUpdate` in Dart to include those columns.
{% endblock %}

Note that this requires a fairly recent sqlite3 version (3.24.0) that might not
be available on older Android devices when using `drift_sqflite`. `NativeDatabases`
and `sqlite3_flutter_libs` includes the latest sqlite on Android, so consider using
it if you want to support upserts.

Also note that the returned rowid may not be accurate when an upsert took place.

### Returning

You can use `insertReturning` to insert a row or companion and immediately get the row it inserts.
The returned row contains all the default values and incrementing ids that were
generated.

__Note:__ This uses the `RETURNING` syntax added in sqlite3 version 3.35, which is not available on most operating systems by default. When using this method, make sure that you have a recent sqlite3 version available. This is the case with `sqlite3_flutter_libs`.

For instance, consider this snippet using the tables from the [getting started guide]({{ '../setup.md' | pageUrl }}):

```dart
final row = await into(todos).insertReturning(TodosCompanion.insert(
  title: 'A todo entry',
  content: 'A description',
));
```

The `row` returned has the proper `id` set. If a table has further default
values, including dynamic values like `CURRENT_TIME`, then those would also be
set in a row returned by `insertReturning`.
