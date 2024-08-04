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

### Important Considerations


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

### Remove Column

To remove a column from a table, use the `dropColumn` method in the migration step.

{{ load_snippet('drop_column','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}


However, there are some considerations when removing a column:

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

However, there are some considerations when adding a column:

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


### Removing a Table, Index, or Trigger

To remove a table, index, or trigger, use the `drop` method in the migration step.

{{ load_snippet('drop_table','lib/snippets/migrations/step_by_step.dart.excerpt.json') }}



## Customizing step-by-step migrations

The `stepByStep` function generated by the `drift_dev schema steps` command gives you an
`OnUpgrade` callback.
But you might want to customize the upgrade behavior, for instance by adding foreign key
checks afterwards (as described in [tips](index.md#tips)).

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
