---
title: "Migrations"
weight: 10
description: Define what happens when your database gets created or updated
aliases:
 - /migrations
---

Moor provides a migration API that can be used to gradually apply schema changes after bumping
the `schemaVersion` getter inside the `Database` class. To use it, override the `migration`
getter. Here's an example: Let's say you wanted to add a due date to your todo entries:
```dart
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 10)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()(); // new, added column
}
```
We can now change the `database` class like this:
```dart
  @override
  int get schemaVersion => 2; // bump because the tables have changed

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) {
      return m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        // we added the dueDate property in the change from version 1
        await m.addColumn(todos, todos.dueDate);
      }
    }
  );

  // rest of class can stay the same
```
You can also add individual tables or drop them - see the reference of [Migrator](https://pub.dev/documentation/moor/latest/moor/Migrator-class.html)
for all the available options. You can't use the high-level query API in migrations - calling `select` or similar 
methods will throw.

`sqlite` can feel a bit limiting when it comes to migrations - there only are methods to create tables and columns.
Existing columns can't be altered or removed. A workaround is described [here](https://stackoverflow.com/a/805508), it
can be used together with `customStatement` to run the statements.

## Complex migrations

Sqlite has builtin statements for simple changes, like adding columns or dropping entire tables.
More complex migrations require a [12-step procedure](https://www.sqlite.org/lang_altertable.html#otheralter) that
involes creating a copy of the table and copying over data from the old table.
Moor 3.4 introduced the `TableMigration` api to automate most of this procedure, making it easier and safer to use.

To start the migration, moor will create a new instance of the table with the current schema. Next, it will copy over
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

Internally, moor will use a `INSERT INTO SELECT` statement to copy old data. In this case, it would look like
`INSERT INTO temporary_todos_copy SELECT id, title, content, CAST(category AS INT) FROM todos`.
As you can see, moor will use the expression from the `columnTransformer` map and fall back to just copying the column
otherwise.   
If you're introducing new columns in a table migration, be sure to include them in the `newColumns` parameter of
`TableMigration`. Moor will ensure that those columns have a default value or a transformation in `columnTransformer`.
Of course, moor won't attempt to copy `newColumns` from the old table either.

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

```dart
onUpgrade: (m, old, to) async {
  if (old <= yourOldVersion) {
    await m.alterTable(
      TableMigration(
        todos,
        columnTransformer: {
          todos.category: todos.category.cast<int>(),
        }
      ),
    );
  }
}
```

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

## Post-migration callbacks

The `beforeOpen` parameter in `MigrationStrategy` can be used to populate data after the database has been created.
It runs after migrations, but before any other query. Note that it will be called whenever the database is opened,
regardless of whether a migration actually ran or not. You can use `details.hadUpgrade` or `details.wasCreated` to
check whether migrations were necessary:

```dart
beforeOpen: (details) async {
    if (details.wasCreated) {
      final workId = await into(categories).insert(Category(description: 'Work'));
    
      await into(todos).insert(TodoEntry(
            content: 'A first todo entry',
            category: null,
            targetDate: DateTime.now(),
      ));
    
      await into(todos).insert(
            TodoEntry(
              content: 'Rework persistence code',
              category: workId,
              targetDate: DateTime.now().add(const Duration(days: 4)),
      ));
    }
},
```
You could also activate pragma statements that you need:
```dart
beforeOpen: (details) async {
  if (details.wasCreated) {
    // ...
  }
  await customStatement('PRAGMA foreign_keys = ON');
}
```

## During development

During development, you might be changing your schema very often and don't want to write migrations for that
yet. You can just delete your apps' data and reinstall the app - the database will be deleted and all tables
will be created again. Please note that uninstalling is not enough sometimes - Android might have backed up
the database file and will re-create it when installing the app again.

You can also delete and re-create all tables every time your app is opened, see [this comment](https://github.com/simolus3/moor/issues/188#issuecomment-542682912)
on how that can be achieved.