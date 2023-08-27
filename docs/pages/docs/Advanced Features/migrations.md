---
data:
  title: "Migrations"
  weight: 10
  description: Define what happens when your database gets created or updated
aliases:
  - /migrations
template: layouts/docs/single
---

As your app grows, you may want to change the table structure for your drift database:
New features need new columns or tables, and outdated columns may have to be altered or
removed altogether.
When making changes to your database schema, you need to write migrations enabling users with
an old version of your app to convert to the database expected by the latest version.
With incorrect migrations, your database ends up in an inconsistent state which can cause crashes
or data loss. This is why drift provides dedicated test tools and APIs to make writing migrations
easy and safe.

{% assign snippets = 'package:drift_docs/snippets/migrations/migrations.dart.excerpt.json' | readString | json_decode %}

## Manual setup {#basics}

Drift provides a migration API that can be used to gradually apply schema changes after bumping
the `schemaVersion` getter inside the `Database` class. To use it, override the `migration`
getter.

Here's an example: Let's say you wanted to add a due date to your todo entries (`v2` of the schema).
Later, you decide to also add a priority column (`v3` of the schema).

{% include "blocks/snippet" snippets = snippets name = 'table' %}

We can now change the `database` class like this:

{% include "blocks/snippet" snippets = snippets name = 'start' %}

You can also add individual tables or drop them - see the reference of [Migrator](https://pub.dev/documentation/drift/latest/drift/Migrator-class.html)
for all the available options.

You can also use higher-level query APIs like `select`, `update` or `delete` inside a migration callback.
However, be aware that drift expects the latest schema when creating SQL statements or mapping results.
For instance, when adding a new column to your database, you shouldn't run a `select` on that table before
you've actually added the column. In general, try to avoid running queries in migration callbacks if possible.

`sqlite` can feel a bit limiting when it comes to migrations - there only are methods to create tables and columns.
Existing columns can't be altered or removed. A workaround is described [here](https://stackoverflow.com/a/805508), it
can be used together with `customStatement` to run the statements.
Alternatively, [complex migrations](#complex-migrations) described on this page help automating this.

### Tips

To ensure your schema stays consistent during a migration, you can wrap it in a `transaction` block.
However, be aware that some pragmas (including `foreign_keys`) can't be changed inside transactions.
Still, it can be useful to:

- always re-enable foreign keys before using the database, by enabling them in [`beforeOpen`](#post-migration-callbacks).
- disable foreign-keys before migrations
- run migrations inside a transaction
- make sure your migrations didn't introduce any inconsistencies with `PRAGMA foreign_key_check`.

With all of this combined, a migration callback can look like this:

{% include "blocks/snippet" snippets = snippets name = 'structured' %}

## Migration workflow

While migrations can be written manually without additional help from drift, dedicated tools testing your migrations help
to ensure that they are correct and aren't loosing any data.

Drift's migration tooling consists of the following steps:

1. After each change to your schema, use a tool to export the current schema into a separate file.
2. Use a drift tool to generate test code able to verify that your migrations are bringing the database
   into the expected schema.
3. Use generated code to make writing schema migrations easier.

### Setup

As described by the first step, you can export the schema of your database into a JSON file.
It is recommended to do this once intially, and then again each time you change your schema
and increase the `schemaVersion` getter in the database.

You should store these exported files in your repository and include them in source control.
This guide assumes a top-level `drift_schemas/` folder in your project, like this:

```
my_app
  .../
  lib/
    database/
      database.dart
      database.g.dart
  test/
    generated_migrations/
      schema.dart
      schema_v1.dart
      schema_v2.dart
  drift_schemas/
    drift_schema_v1.json
    drift_schema_v2.json
  pubspec.yaml
```

Of course, you can also use another folder or a subfolder somewhere if that suits your workflow
better.

{% block "blocks/alert" title="Examples available" %}
Exporting schemas and generating code for them can't be done with `build_runner` alone, which is
why this setup described here is necessary.

We hope it's worth it though! Verifying migrations can give you confidence that you won't run
into issues after changing your database.
If you get stuck along the way, don't hesitate to [open a discussion about it](https://github.com/simolus3/drift/discussions).

Also there are two examples in the drift repository which may be useful as a reference:

- A [Flutter app](https://github.com/simolus3/drift/tree/latest-release/examples/app)
- An [example specific to migrations](https://github.com/simolus3/drift/tree/latest-release/examples/migrations_example).
{% endblock %}

#### Exporting the schema

To begin, lets create the first schema representation:

```
$ mkdir drift_schemas
$ dart run drift_dev schema dump lib/database/database.dart drift_schemas/
```

This instructs the generator to look at the database defined in `lib/database/database.dart` and extract
its schema into the new folder.

After making a change to your database schema, you can run the command again. For instance, let's say we
made a change to our tables and increased the `schemaVersion` to `2`. To dump the new schema, just run the
command again:

```
$ dart run drift_dev schema dump lib/database/database.dart drift_schemas/
```

You'll need to run this command every time you change the schema of your database and increment the `schemaVersion`.

Drift will name the files in the folder `drift_schema_vX.json`, where `X` is the current `schemaVersion` of your
database.
If drift is unable to extract the version from your `schemaVersion` getter, provide the full path explicitly:

```
$ dart run drift_dev schema dump lib/database/database.dart drift_schemas/drift_schema_v3.json
```

{% block "blocks/alert" title='<i class="fas fa-lightbulb"></i> Dumping a database' color="success" %}
If, instead of exporting the schema of a database class, you want to export the schema of an existing sqlite3
database file, you can do that as well! `drift_dev schema dump` recognizes a sqlite3 database file as its first
argument and can extract the relevant schema from there.
{% endblock %}

### Generating step-by-step migrations {#step-by-step}

With all your database schemas exported into a folder, drift can generate code that makes it much
easier to write schema migrations "step-by-step" (incrementally from each version to the next one).

This code is stored in a single-file, which you can generate like this:

```
$ dart run drift_dev schema steps drift_schemas/ lib/database/schema_versions.dart
```

The generated code contains a `stepByStep` method which you can use as a callback to the `onUpgrade`
parameter of your `MigrationStrategy`.
As an example, here is the [initial](#basics) migration shown at the top of this page, but rewritten using
the generated `stepByStep` function:

{% include "blocks/snippet" snippets = snippets name = 'stepbystep' %}

`stepByStep` expects a callback for each schema upgrade responsible for running the partial migration.
That callback receives two parameters: A migrator `m` (similar to the regular migrator you'd get for
`onUpgrade` callbacks) and a `schema` parameter that gives you access to the schema at the version you're
migrating to.
For instance, in the `from1To2` function, `schema` provides getters for the database schema at version 2.
The migrator passed to the function is also set up to consider that specific version by default.
A call to `m.recreateAllViews()` would re-create views at the expected state of schema version 2, for instance.

#### Customizing step-by-step migrations

The `stepByStep` function generated by the `drift_dev schema steps` command gives you an
`OnUpgrade` callback.
But you might want to customize the upgrade behavior, for instance by adding foreign key
checks afterwards (as described in [tips](#tips)).

The `Migrator.runMigrationSteps` helper method can be used for that, as this example
shows:

{% include "blocks/snippet" snippets = snippets name = 'stepbystep2' %}

Here, foreign keys are disabled before runnign the migration and re-enabled afterwards.
A check ensuring no inconsistencies occurred helps catching issues with the migration
in debug modes.

### Writing tests

After you've exported the database schemas into a folder, you can generate old versions of your database class
based on those schema files.
For verifications, drift will generate a much smaller database implementation that can only be used to
test migrations.

You can put this test code whereever you want, but it makes sense to put it in a subfolder of `test/`.
If we wanted to write them to `test/generated_migrations/`, we could use

```
$ dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
```

After that setup, it's finally time to write some tests! For instance, a test could look like this:

```dart
import 'package:my_app/database/database.dart';

import 'package:test/test.dart';
import 'package:drift_dev/api/migrations.dart';

// The generated directory from before.
import 'generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    // GeneratedHelper() was generated by drift, the verifier is an api
    // provided by drift_dev.
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('upgrade from v1 to v2', () async {
    // Use startAt(1) to obtain a database connection with all tables
    // from the v1 schema.
    final connection = await verifier.startAt(1);
    final db = MyDatabase(connection);

    // Use this to run a migration to v2 and then validate that the
    // database has the expected schema.
    await verifier.migrateAndValidate(db, 2);
  });
}
```

In general, a test looks like this:

1. Use `verifier.startAt()` to obtain a [connection](https://drift.simonbinder.eu/api/drift/databaseconnection-class)
  to a database with an initial schema.
  This database contains all your tables, indices and triggers from that version, created by using `Migrator.createAll`.
2. Create your application database with that connection - you can forward the `DatabaseConnection` to the
  `GeneratedDatabase.connect()` constructor on the parent class for this.
3. Call `verifier.migrateAndValidate(db, version)`. This will initiate a migration towards the target version (here, `2`).
  Unlike the database created by `startAt`, this uses the migration logic you wrote for your database.

`migrateAndValidate` will extract all `CREATE` statement from the `sqlite_schema` table and semantically compare them.
If it sees anything unexpected, it will throw a `SchemaMismatch` exception to fail your test.

{% block "blocks/alert" title="Writing testable migrations" %}
To test migrations _towards_ an old schema version (e.g. from `v1` to `v2` if your current version is `v3`),
you're `onUpgrade` handler must be capable of upgrading to a version older than the current `schemaVersion`.
For this, check the `to` parameter of the `onUpgrade` callback to run a different migration if necessary.
{% endblock %}

#### Verifying data integrity

In addition to the changes made in your table structure, its useful to ensure that data that was present before a migration
is still there after it ran.
You can use `schemaAt` to obtain a raw `Database` from the `sqlite3` package in addition to a connection.
This can be used to insert data before a migration. After the migration ran, you can then check that the data is still there.

Note that you can't use the regular database class from you app for this, since its data classes always expect the latest
schema. However, you can instruct drift to generate older snapshots of your data classes and companions for this purpose.
To enable this feature, pass the `--data-classes` and `--companions` command-line arguments to the `drift_dev schema generate`
command:

```
$ dart run drift_dev schema generate --data-classes --companions drift_schemas/ test/generated_migrations/
```

Then, you can import the generated classes with an alias:

```dart
import 'generated_migrations/schema_v1.dart' as v1;
import 'generated_migrations/schema_v2.dart' as v2;
```

This can then be used to manually create and verify data at a specific version:

```dart
void main() {
  // ...
  test('upgrade from v1 to v2', () async {
    final schema = await verifier.schemaAt(1);

    // Add some data to the users table, which only has an id column at v1
    final oldDb = v1.DatabaseAtV1.connect(schema.newConnection());
    await oldDb.into(oldDb.users).insert(const v1.UsersCompanion(id: Value(1)));
    await oldDb.close();

    // Run the migration and verify that it adds the name column.
    final db = Database(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);
    await db.close();

    // Make sure the user is still here
    final migratedDb = v2.DatabaseAtV2.connect(schema.newConnection());
    final user = await migratedDb.select(migratedDb.users).getSingle();
    expect(user.id, 1);
    expect(user.name, 'no name'); // default from the migration
    await migratedDb.close();
  });
}
```

## Complex migrations

Sqlite has builtin statements for simple changes, like adding columns or dropping entire tables.
More complex migrations require a [12-step procedure](https://www.sqlite.org/lang_altertable.html#otheralter) that
involves creating a copy of the table and copying over data from the old table.
Drift 3.4 introduced the `TableMigration` api to automate most of this procedure, making it easier and safer to use.

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

You can also delete and re-create all tables every time your app is opened, see [this comment](https://github.com/simolus3/drift/issues/188#issuecomment-542682912)
on how that can be achieved.

## Verifying a database schema at runtime

Instead (or in addition to) [writing tests](#verifying-migrations) to ensure your migrations work as they should,
you can use a new API from `drift_dev` 1.5.0 to verify the current schema without any additional setup.

{% assign runtime_snippet = 'package:drift_docs/snippets/migrations/runtime_verification.dart.excerpt.json' | readString | json_decode %}

{% include "blocks/snippet" snippets = runtime_snippet name = '' %}

When you use `validateDatabaseSchema`, drift will transparently:

- collect information about your database by reading from `sqlite3_schema`.
- create a fresh in-memory instance of your database and create a reference schema with `Migrator.createAll()`.
- compare the two. Ideally, your actual schema at runtime should be identical to the fresh one even though it
  grew through different versions of your app.

When a mismatch is found, an exception with a message explaining exactly where another value was expected will
be thrown.
This allows you to find issues with your schema migrations quickly.
