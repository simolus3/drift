---
data:
  title: "Testing migrations"
  weight: 30
  description: Generate test code to write unit tests for your migrations.
template: layouts/docs/single
---

{% assign snippets = 'package:drift_docs/snippets/migrations/tests/schema_test.dart.excerpt.json' | readString | json_decode %}
{% assign verify = 'package:drift_docs/snippets/migrations/tests/verify_data_integrity_test.dart.excerpt.json' | readString | json_decode %}

While migrations can be written manually without additional help from drift, dedicated tools testing
your migrations help to ensure that they are correct and aren't loosing any data.

Drift's migration tooling consists of the following steps:

1. After each change to your schema, use a tool to export the current schema into a separate file.
2. Use a drift tool to generate test code able to verify that your migrations are bringing the database
   into the expected schema.
3. Use generated code to make writing schema migrations easier.

This page describes steps 2 and 3. It assumes that you're already following step 1 by
[exporting your schema]({{ 'exports.md' }}) when it changes.

## Writing tests

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

{% include "blocks/snippet" snippets = snippets name = 'setup' %}

In general, a test looks like this:

1. Use `verifier.startAt()` to obtain a [connection](https://drift.simonbinder.eu/api/drift/databaseconnection-class)
   to a database with an initial schema.
   This database contains all your tables, indices and triggers from that version, created by using `Migrator.createAll`.
2. Create your application database with that connection. For this, create a constructor in your database class that
   accepts a `QueryExecutor` and forwards it to the super constructor in `GeneratedDatabase`.
   Then, you can pass the result of calling `newConnection()` to that constructor to create a test instance of your
   database.
3. Call `verifier.migrateAndValidate(db, version)`. This will initiate a migration towards the target version (here, `2`).
   Unlike the database created by `startAt`, this uses the migration logic you wrote for your database.

`migrateAndValidate` will extract all `CREATE` statement from the `sqlite_schema` table and semantically compare them.
If it sees anything unexpected, it will throw a `SchemaMismatch` exception to fail your test.

{% block "blocks/alert" title="Writing testable migrations" %}
To test migrations _towards_ an old schema version (e.g. from `v1` to `v2` if your current version is `v3`),
you're `onUpgrade` handler must be capable of upgrading to a version older than the current `schemaVersion`.
For this, check the `to` parameter of the `onUpgrade` callback to run a different migration if necessary.
Or, use [step-by-step migrations]({{ 'step_by_step.md' | pageUrl }}) which do this automatically.
{% endblock %}

## Verifying data integrity

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

{% include "blocks/snippet" snippets = verify name = 'imports' %}

This can then be used to manually create and verify data at a specific version:

{% include "blocks/snippet" snippets = verify name = 'main' %}
