---

title: Overview
description: Tooling and APIs to safely change the schema of your database.

---

Databases use strict table structures to ensure safe queries. These structures are stored in the database and can only be changed through migrations. Drift provides tools to easily write, test, and execute these migrations as part of your app development.


## During Development

During development, you might be changing your schema very often and writing migrations will start to become cumbersome. 
To avoid this headache, use an in-memory database together with an `beforeOpen` callback to populate the database with initial data.

??? example "In-memory database"

    Use a configuration similar to the one below to use a temporary in-memory database during development. 

    You'll only have to write migrations when you're ready to update your app :tada: 

    {{ load_snippet('dev_migrations','lib/snippets/migrations/dev_without_migrations.dart.excerpt.json') }}

    
## Example Schema

All the examples on this page use the following schema:

??? example "Schema"

    {{ load_snippet('table','lib/snippets/migrations/migrations.dart.excerpt.json', indent=4) }}


# Migration Overview

Migrations are performed in steps, with each step updating the schema until the final schema is reached.

For instance:

- Version 1: A table with a `content` column.
- Version 2: Add a `dueDate` column.
- Version 3: Add a `priority` column.

In the above example, you would write two migrations: one to add the `dueDate` column and another to add the `priority` column. These migrations are executed in order to update the schema from version 1 to version 3.

## Versioning

The current schema version is in the `schemaVersion` getter on the database. This value is used to determine which migrations need to be run.

{{ load_snippet('schemaVersion','lib/snippets/migrations/migrations.dart.excerpt.json') }}


## Initial Schema Creation

The `MigrationStrategy.onCreate` callback is configured by default to create all tables in the database. No additional configuration is needed. You can still override this callback to perform additional actions when the database is created.


## Writing Migrations

The `MigrationStrategy.onUpgrade` callback is when the version of the database is higher than the current schema version. This callback is where you define the migrations to update the schema.

### Guided Migrations

Drift provides a set of tools to help you write migrations easily.
By exporting each iteration of your database schema, you can develop migrations progressively, having access to the earlier schema for reference.  

See the [Guided Migrations](./step_by_step.md) section for more information.





### Manual Migrations


You can write migrations manually by using the `from` and `to` parameters to check the current schema version and execute the necessary migrations.

{{ load_snippet('manualOnUpgrade','lib/snippets/migrations/migrations.dart.excerpt.json') }}

!!! warning "Manual Migrations"

    We don't recommend writing migrations manually. It can be error-prone and difficult to maintain.  
    We recommend using the tools provided by drift to create a [Guided Migration](#guided-migrations) instead.





## Post-Migration Callbacks

Once the database is created and the migrations are complete, the `MigrationStrategy.beforeOpen` callback is called. This callback is useful for populating the database with initial data or enabling pragmas.

{{ load_snippet('beforeOpen','lib/snippets/migrations/migrations.dart.excerpt.json') }}

The `details` parameter contains information about the database, such as whether it was created or if migrations were run.


## Verify Migrations

Drift provides a convenient way to ensure your database schema is correct after migrations, without requiring additional setup or writing separate tests.

Use the `validateDatabaseSchema` function from `drift_dev` to verify the current schema of your database:

{{ load_snippet('verify_scheme','lib/snippets/migrations/runtime_verification.dart.excerpt.json') }}

Drift will automatically compare your current database schema to what it should be based on your current app version. 

If there's any mismatch between the expected schema and the actual schema, Drift will throw an exception with a detailed message. This message will explain exactly where and how the schema differs from what's expected.