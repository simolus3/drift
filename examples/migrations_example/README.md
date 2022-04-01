Example to demonstrate tests for schema migrations.

See `test/migration_test.dart` on how to use the generated verification code.

## Workflow

### Schema changes

After adapting a schema and incrementing the `schemaVersion` in the database, run

```
dart run drift_dev schema dump lib/database.dart drift_migrations/
```

Replace `_v2` with the current `schemaVersion`.

### Generating test code

Run

```
dart run drift_dev schema generate drift_migrations/ test/generated/ --data-classes --companions
```

We're also using test code inside `lib/` to run migrations with older definitions of tables.
This isn't required for all migrations, but can be useful in some cases.

```
dart run drift_dev schema generate drift_migrations/ lib/src/generated
```
