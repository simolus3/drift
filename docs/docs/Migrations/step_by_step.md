---

title: Guided Migrations
description: Writing migrations between schema versions using the step-by-step pattern.

---

Drift provides a set of tools to help you write migrations in a manner which is testable, scalable, and easy to maintain. By exporting each iteration of your database schema, you can develop migrations progressively, having access to the earlier schema for reference.

The following steps outline how to write migrations using the step-by-step pattern:

## Example Schema

All the examples on this page use the following schema:

??? example "Schema"

    {{ load_snippet('table','lib/snippets/migrations/migrations.dart.excerpt.json', indent=4) }}

## Tips


- **Transactions**: Each migration step should be wrapped in a transaction to ensure data integrity.
    ```dart
    await transaction(() async {
      // Migration code here
    });
    ```
- **Foreign Key Checks**: Disable foreign key checks before running the migration and re-enable them afterwards to prevent foreign key violations. Consider adding a check to ensure no inconsistencies occurred during the migration.
  
    ??? example "Example"
          
        {{ load_snippet('stepbystep2','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

- **Testing**: Drift makes it very easy to test migrations. See the [Testing Migrations](testing.md) guide for more information.
- **Avoid Querying In Migrations**: While it's possible to run queries in migration callbacks, it's not recommended. Drift expects the latest schema when querying the database, so if the schema has changed, the query might fail. 


## Step 1: Saving Schema Versions

After finalizing a new version of your database schema:


1. Increment the schemaVersion in your database definition.
2. Use the `drift_dev` tool to save the current schema:

  ```bash
  dart run drift_dev schema dump lib/database/database.dart drift_schemas/
  ```


This command takes your database file path (`lib/database/database.dart`) and outputs to the specified directory (`drift_schemas/`). It creates a new file (e.g., `drift_schema_v2.json`) containing the current schema.

!!! tip "Commit Schema Files"
    Make sure to commit these schema files to version control. They're crucial for managing migrations in future updates.


## Step 2: Generating a Step-by-Step Migration Assistant

After saving the schema, use the `drift_dev` tool to generate a `stepByStep` migration assistant:

```bash
dart run drift_dev schema steps drift_schemas/ lib/database/schema_versions.dart
```

This command generates a new file (`lib/database/schema_versions.dart`) containing the `stepByStep` migration assistant. This assistant provides a guided way to write migrations for each schema version.

{{ load_snippet('stepbystep','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

## Step 3: Writing Migrations

In each step of the `stepByStep` function, write the migration code to update the schema to the next version. 

!!! note "SQlite Version"
    This migrations guide assumes you're using SQLite and a version greater or equal to 3.38.0. If you're using an older version, you might need to adjust the migration code accordingly.

    The version of `sqlite3` installed automatically by `drift_flutter`/`sqlite3_flutter_libs` meets this requirement.

### Adding a Table, Index, View or Trigger

To add a table, index, or trigger, use the `create` method in the migration step.

{{ load_snippet('drop_table','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

### Removing a Table, Index or Trigger

To remove a table, index, or trigger, use the `drop` method in the migration step.

{{ load_snippet('drop_table','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

When a table is dropped, all indexes, views, and triggers associated with the table are also removed.

#### Foreign Key Constraints

If other tables have foreign key constraints that reference the table you want to drop, it depends on what action is set for the foreign key:

- If the reference has an `KeyAction.noAction` (default), `KeyAction.restrict` the migration will fail.
- If the reference has an `KeyAction.setNull`, the migration will succeed, but the foreign key will be set to `null`.
- If the reference has an `KeyAction.cascade`, the migration will succeed, and all rows in the referencing table will be deleted.
- If the reference has an `KeyAction.setDefault`, the migration will succeed, and the default value will be set. If this default value is not `null`, the migration will fail.

It's recommended to remove the foreign key constraints first before dropping the table.

### Remove Column

To remove a column from a table, use the `dropColumn` method in the migration step.

{{ load_snippet('drop_column','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

However, you may need to use an [Alter Table](#removing-any-column) statement to remove a column in some cases:

- **Primary Keys**: You cannot remove a column from a table if it is part of the primary key.
    {{ load_snippet('drop_primary_key','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}
- **Unique Constraints**: You cannot remove a column with `dropColumn` if it is part of a unique constraint.
    {{ load_snippet('drop_column_with_unique','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}
- **Indexed Columns**: You cannot remove a column from a table if it is part of an index. Drop the index first.
    {{ load_snippet('drop_column_with_index','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}
- **Foreign Key Constraints**: If another table has a column that references the column you want to remove, you must remove the foreign key constraint first.
- **Used in Expressions**: You cannot remove a column from a table if it is used in an expression anywhere on the table. These are typically found on:

      - **Generated Columns**
      - **Check Constraints**
      - **Views**
      - **Triggers**
      - **Partial Indexes**  
  
    For example:
      {{ load_snippet('drop_column_with_expression','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}


### Add Column

To add a column to a table, use the `addColumn` method in the migration step.

{{ load_snippet('add_column','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

However, you may need to use an [Alter Table](#adding-any-column) statement to add a column in some cases:

- **Non-Nullable Columns**: If the column is not nullable, you must provide a default value.
  {{ load_snippet('add_required_column','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}
- **Unique Constraints**: You cannot add a column to a table if it is part of a unique constraint.
  {{ load_snippet('add_column_with_unique','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}
- **Primary Key**: You cannot add a column to a table if it is part a primary key.
- **Stored Generated Columns**: A stored generated column cannot be added with the `addColumn` method.
  {{ load_snippet('add_generated_column','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}
- **Default Value Expression**: If you provide a default value expression, it must be a constant value. For example, `defaultValue: Constant(0)` is valid, but `defaultValue: currentDateAndTime` is not.
  {{ load_snippet('add_column_with_expression','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}



!!! note "Empty Table"

    If the table is empty, or you simply don't care about the existing data, you can drop the table entirely and recreate it to add the column.

### Rename Table

To rename a table, use the `renameTable` method in the migration step.

{{ load_snippet('rename_table','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

!!! note "Foreign Key Constraints"

    If you are using `sqlite` installed automatically by `drift_flutter`/`sqlite3_flutter_libs`, foreign key constraints are handled gracefully. Any other tables with foreign key constraints that reference the renamed table will be updated automatically.

    However older versions of `sqlite` might not handle this gracefully. See the [SQLite documentation](https://www.sqlite.org/lang_altertable.html#renametable) for more information.

### Rename Column

If you only want to change the name of the column in Dart code, you can use the `named` constructor on the table to customize the column name to what it is in the database and rename the getter in the Dart code.  
Now a migration is not needed to rename the column in the database.

{{ load_snippet('fake_rename_column','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

If you want to rename the column in the database, you can use the `renameColumn` method in the migration step.

{{ load_snippet('rename_column','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

### Alter Table

To perform more complex operations on a table, `alterTable` can be used in the migration step.

An `AlterTable` operation works by creating a new table with the desired schema, copying the data from the old table to the new table, and then dropping the old table.

#### Adding any Column

Most columns which could not be added with `addColumn` can be added with `alterTable`.

The only exception is column which cannot store `null` and does not have a default value. This will fail because there is no way to populate the current rows with a value.

{{ load_snippet('add_any_column','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

While `alterTable` can add any column, it is a more expensive operation than `addColumn` and should only be used when necessary.

#### Removing any Column

Any column which could not be removed with `dropColumn` can be removed with `alterTable`.

Just run `alterTable` with the new table schema as shown below.

{{ load_snippet('remove_any_column','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

#### Changing Constraints

This is one of the most common operations when altering a table. 

For example:

- **Adding a Unique Constraint**
- **Removing a Unique Constraint**
- **Adding a Check Constraint**
- **Removing a Check Constraint**
- **Adding a Foreign Key Constraint**
- **Removing a Foreign Key Constraint**
- **Adding a Not Null Constraint**
- **Removing a Not Null Constraint**

For all these operations, you can use `alterTable` with the new table schema as shown below.

{{ load_snippet('remove_any_column','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

#### Changing Column Type

To change the type of a column, you can use `alterTable` with a `columnTransformer` which defines how columns will be read from the old table and written to the new table.

{{ load_snippet('change_type','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

## Customizing step-by-step migrations

The `stepByStep` function generated by the `drift_dev schema steps` command gives you an
`OnUpgrade` callback.
But you might want to customize the upgrade behavior, for instance by adding foreign key
checks afterwards as described in [tips](#tips).

The `Migrator.runMigrationSteps` helper method can be used for that, as this example
shows:

{{ load_snippet('stepbystep2','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

Here, foreign keys are disabled before runnign the migration and re-enabled afterwards.
A check ensuring no inconsistencies occurred helps catching issues with the migration
in debug modes.

## Moving to step-by-step migrations

If you've been using drift before `stepByStep` was added to the library, or if you've never exported a schema,
you can move to step-by-step migrations by pinning the `from` value in `Migrator.runMigrationSteps` to a known
starting point.

This allows you to perform all prior migration work to get the database to the "starting" point for
`stepByStep` migrations, and then use `stepByStep` migrations beyond that schema version.

{{ load_snippet('stepbystep3','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}

Here, we give a "floor" to the `from` value of `2`, since we've performed all other migration work to get to
this point. From now on, you can generate step-by-step migrations for each schema change.

If you did not do this, a user migrating from schema 1 directly to schema 3 would not properly walk migrations
and apply all migration changes required.
