---
data:
  title: "The migrator API"
  weight: 50
  description: How to run `ALTER` statements and complex table migrations.
template: layouts/docs/single
---

{% assign snippets = 'package:drift_docs/snippets/migrations/migrations.dart.excerpt.json' | readString | json_decode %}

You can write migrations manually by using `customStatement()` in a migration
callback. However, the callbacks also give you an instance of `Migrator` as a
parameter. This class knows about the target schema of the database and can be
used to create, drop and alter most elements in your schema.

## Migrating views, triggers and indices

When changing the definition of a view, a trigger or an index, the easiest way
to update the database schema is to drop and re-create the element.
With the `Migrator` API, this is just a matter of calling `await drop(element)`
followed by `await create(element)`, where `element` is the trigger, view or index
to update.

Note that the definition of a Dart-defined view might change without modifications
to the view class itself. This is because columns from a table are referenced with
a getter. When renaming a column through `.named('name')` in a table definition
without renaming the getter, the view definition in Dart stays the same but the
`CREATE VIEW` statement changes.

A headache-free solution to this problem is to just re-create all views in a
migration, for which the `Migrator` provides the `recreateAllViews` method.

## Complex migrations

Sqlite has builtin statements for simple changes, like adding columns or dropping entire tables.
More complex migrations require a [12-step procedure](https://www.sqlite.org/lang_altertable.html#otheralter) that
involves creating a copy of the table and copying over data from the old table.
Drift 2.4 introduced the `TableMigration` API to automate most of this procedure, making it easier and safer to use.

To start the migration, drift will create a new instance of the table with the current schema. Next, it will copy over
rows from the old table.
In most cases, for instance when changing column types, we can't just copy over each row without changing its content.
Here, you can use a `columnTransformer` to apply a per-row transformation.
The `columnTransformer` is a map from columns to the sql expression that will be used to copy the column from the
old table.
For instance, if we wanted to cast a column before copying it, we could use:

```dart
columnTransformer: {
  todos.category: todos.category.cast<int>(),
}
```

Internally, drift will use a `INSERT INTO SELECT` statement to copy old data. In this case, it would look like
`INSERT INTO temporary_todos_copy SELECT id, title, content, CAST(category AS INT) FROM todos`.
As you can see, drift will use the expression from the `columnTransformer` map and fall back to just copying the column
otherwise.
If you're introducing new columns in a table migration, be sure to include them in the `newColumns` parameter of
`TableMigration`. Drift will ensure that those columns have a default value or a transformation in `columnTransformer`.
Of course, drift won't attempt to copy `newColumns` from the old table either.

Regardless of whether you're implementing complex migrations with `TableMigration` or by running a custom sequence
of statements, we strongly recommend to write integration tests covering your migrations. This helps to avoid data
loss caused by errors in a migration.

Here are some examples demonstrating common usages of the table migration api:

### Changing the type of a column

Let's say the `category` column in `Todos` used to be a non-nullable `text()` column that we're now changing to a
nullable int. For simplicity, we assume that `category` always contained integers, they were just stored in a text
column that we now want to adapt.

```patch
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 10)();
  TextColumn get content => text().named('body')();
-  IntColumn get category => text()();
+  IntColumn get category => integer().nullable()();
}
```

After re-running your build and incrementing the schema version, you can write a migration:

{% include "blocks/snippet" snippets = snippets name = 'change_type' %}

The important part here is the `columnTransformer` - a map from columns to expressions that will
be used to copy the old data. The values in that map refer to the old table, so we can use
`todos.category.cast<int>()` to copy old rows and transform their `category`.
All columns that aren't present in `columnTransformer` will be copied from the old table without
any transformation.

### Changing column constraints

When you're changing columns constraints in a way that's compatible to existing data (e.g. changing
non-nullable columns to nullable columns), you can just copy over data without applying any
transformation:

```dart
await m.alterTable(TableMigration(todos));
```

### Deleting columns

Deleting a column that's not referenced by a foreign key constraint is easy too:

```dart
await m.alterTable(TableMigration(yourTable));
```

To delete a column referenced by a foreign key, you'd have to migrate the referencing
tables first.

### Renaming columns

If you're renaming a column in Dart, note that the easiest way is to just rename the getter and use
`named`: `TextColumn newName => text().named('old_name')()`. That is fully backwards compatible and
doesn't require a migration.

If you know your app runs on sqlite 3.25.0 or later (it does if you're using `sqlite3_flutter_libs`),
you can also use the `renameColumn` api in `Migrator`:

```dart
m.renameColumn(yourTable, 'old_column_name', yourTable.newColumn);
```

If you do want to change the actual column name in a table, you can write a `columnTransformer` to
use an old column with a different name:

```dart
await m.alterTable(
  TableMigration(
    yourTable,
    columnTransformer: {
      yourTable.newColumn: const CustomExpression('old_column_name')
    },
  )
)
```
