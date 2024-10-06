---

title: Migrations
description: Tooling and APIs to safely change the schema of your database.

---

Drift ensures type-safe queries through a strict schema. To change this schema, you must write migrations. 
Drift provides a range of APIs, command-line tools, and testing utilities to make writing and verifying database migrations easier and more reliable.

## Guided Migrations

Drift offers an all-in-one command for writing and testing migrations.  
This tool helps you write your schema changes incrementally and generates tests to verify that your migrations are correct.

### Configuration

To use the `make-migrations` command, you must add the location of your database(s) to your `build.yaml` file.

```yaml title="build.yaml"
targets:
  $default:
    builders:
      drift_dev:
        options:
          databases:
            # Required: A name for the database and it's path
            my_database: lib/database.dart

            # Optional: Add more databases
            another_db: lib/database2.dart
```

You can also optionally specify the directory where the test files and schema (1) files are stored.
{ .annotate }

1.  Drift will generate multiple schema files, one for each version of your database schema. These files are used to compare the current schema with the previous schema and generate the migration code.

```yaml title="build.yaml"
targets:
  $default:
    builders:
      drift_dev:
        options:
          # The directory where the test files are stored: 
          test_dir: test/drift/ # (default)

          # The directory where the schema files are stored:
          schema_dir: drift_schemas/  # (default)
```

### Usage

Before you start making changes to your initial database schema, run this command to generate the initial schema file.

```bash
dart run drift_dev make-migrations
```
Once this initial schema file is saved, you can start making changes to your database schema.


Once you're happy with the changes, bump the `schemaVersion` in your database class and run the command again.

```bash
dart run drift_dev make-migrations
```

This command will generate the following files:

- A step-by-step migration file will be generated next to your database class. Use this function to write your migrations incrementally. See the [step-by-step migration guide](step_by_step.md) for more information.


- Drift will also generate a test file for your migrations. After you've written your migration, run the tests to verify that your migrations are written correctly.

- Drift will also generate a file which can be used to make the tests validate the data integrity of your migrations. These files should be filled in with before and after data for each migration.

If you get stuck along the way, don't hesitate to [open a discussion about it](https://github.com/simolus3/drift/discussions).


### Example

See the [example](https://github.com/simolus3/drift/tree/develop/examples/migrations_example) in the drift repository for a complete example of how to use the `make-migrations` command.

### Switching to `make-migrations`

If you've already been using the `schema` tools to write migrations, you can switch to `make-migrations` by following these steps:

1. Run the `make-migrations` command to generate the initial schema file.
2. Move all of your existing `schema` files into the schema directory for your database.
3. Run the `make-migrations` command again to generate the step-by-step migration file and test files.

## During development

During development, you might be changing your schema very often and don't want to write migrations for that
yet. You can just delete your apps' data and reinstall the app - the database will be deleted and all tables
will be created again. Please note that uninstalling is not enough sometimes - Android might have backed up
the database file and will re-create it when installing the app again.

You can also delete and re-create all tables every time your app is opened, see [this comment](https://github.com/simolus3/drift/issues/188#issuecomment-542682912)
on how that can be achieved.

## Manual Migrations

!!! warning "Manual migrations are error-prone"
    Writing migrations manually is error-prone and can lead to data loss. We recommend using the `make-migrations` command to generate migrations and tests.

Drift provides a migration API that can be used to gradually apply schema changes after bumping
the `schemaVersion` getter inside the `Database` class. To use it, override the `migration`
getter.

Here's an example: Let's say you wanted to add a due date to your todo entries (`v2` of the schema).
Later, you decide to also add a priority column (`v3` of the schema).

{{ load_snippet('table','lib/snippets/migrations/migrations.dart.excerpt.json') }}

We can now change the `database` class like this:

{{ load_snippet('start','lib/snippets/migrations/migrations.dart.excerpt.json') }}

You can also add individual tables or drop them - see the reference of [Migrator](https://pub.dev/documentation/drift/latest/drift/Migrator-class.html)
for all the available options.

You can also use higher-level query APIs like `select`, `update` or `delete` inside a migration callback.
However, be aware that drift expects the latest schema when creating SQL statements or mapping results.
For instance, when adding a new column to your database, you shouldn't run a `select` on that table before
you've actually added the column. In general, try to avoid running queries in migration callbacks if possible.

## Post-Migration callbacks

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

