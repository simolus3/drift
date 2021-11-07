---
data:
  title: "Migrations"
  weight: 10
  description: Define what happens when your database gets created or updated
aliases:
  - /migrations
template: layouts/docs/single
---

Drift provides a migration API that can be used to gradually apply schema changes after bumping
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

You can also add individual tables or drop them - see the reference of [Migrator](https://pub.dev/documentation/drift/latest/drift/Migrator-class.html)
for all the available options. You can't use the high-level query API in migrations - calling `select` or similar
methods will throw.

`sqlite` can feel a bit limiting when it comes to migrations - there only are methods to create tables and columns.
Existing columns can't be altered or removed. A workaround is described [here](https://stackoverflow.com/a/805508), it
can be used together with `customStatement` to run the statements.

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

## Verifying migrations

Drift contains **experimental** support to verify the integrity of your migrations in unit tests.

To support this feature, drift can help you generate

- a json representation of your database schema
- test databases operating on an older schema version

By using those test databases, drift can help you test migrations from and to any schema version.

{% block "blocks/alert" title="Complex topic ahead" %}
> Writing schema tests is an advanced topic that requires a fairly complex setup described here.
  If you get stuck along the way, don't hesitate to [open a discussion about it](https://github.com/simolus3/moor/discussions).
  Also, there's a working example [in the drift repository](https://github.com/simolus3/moor/tree/master/extras/migrations_example).
{% endblock %}

### Setup

To use this feature, drift needs to know all schemas of your database. A schema is the set of all tables, triggers
and indices that you use in your database.

You can use the [CLI tools]({{ "../CLI.md" | pageUrl }}) to export a json representation of your schema.
In this guide, we'll assume a file layout like the following, where `my_app` is the root folder of your project:

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

The generated migrations implementation and the schema jsons will be generated by drift.
To start writing schemas, create an empty folder named `drift_schemas` in your project.
Of course, you can also choose a different name or use a nested subfolder if you want to.

#### Exporting the schema

To begin, let's create the first schema representation:

```
$ mkdir drift_schemas
$ dart run drift_dev schema dump lib/database/database.dart drift_schemas/drift_schema_v1.json
```

This instructs the generator to look at the database defined in `lib/database/database.dart` and extract
its schema into the new folder.

After making a change to your database schema, you can run the command again. For instance, let's say we
made a change to our tables and increased the `schemaVersion` to `2`. We would then run:

```
$ dart run drift_dev schema dump lib/database/database.dart drift_schemas/drift_schema_v2.json
```

You'll need to run this command every time you change the schema of your database and increment the `schemaVersion`.
Remember to name the files `drift_schema_vX.json`, where `X` is the current `schemaVersion` of your database.

#### Generating test code

After you exported the database schema into a folder, you can generate old versions of your database class
based on those schema files.
For verifications, drift will generate a much smaller database implementation that can only be used to
test migrations.

You can put this test code whereever you want, but it makes sense to put it in a subfolder of `test/`.
If we wanted to write them to `test/generated_migrations/`, we could use

```
$ dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
```

### Writing tests

After that setup, it's finally time to write some tests! For instance, a test could look like this:

```dart
import 'package:my_app/database/database.dart';

import 'package:test/test.dart';
import 'package:drift_dev/api/migrations.dart';

// The generated directory from before.
import 'generated_migrations/schema.dart';

void main() {
  SchemaVerifier verifier;

  setUpAll(() {
    // GeneratedHelper() was generated by drift, the verifier is an api
    // provided by drift_generator.
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('upgrade from v1 to v2', () async {
    // Use startAt(1) to obtain a database connection with all tables
    // from the v1 schema.
    final connection = await verifier.startAt(1);
    final db = MyDatabase.connect(connection);

    // Use this to run a migration to v2 and then validate that the
    // database has the expected schema.
    await verifier.migrateAndValidate(db, 2);
  });
}
```

In general, a test looks like this:

- Use `verifier.startAt()` to obtain a [connection](https://pub.dev/documentation/moor/latest/moor/DatabaseConnection-class.html)
  to a database with an initial schema.
  This database contains all your tables, indices and triggers from that version, created by using `Migrator.createAll`.
- Create your application database (you can enable the [`generate_connect_constructor`]({{ "builder_options.md" | pageUrl }}) to use
  a `DatabaseConnection` directly)
- Call `verifier.migrateAndValidate(db, version)`. This will initiate a migration towards the target version (here, `2`).
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
command.

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
