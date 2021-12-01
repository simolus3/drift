Example to demonstrate tests for schema migrations.

See `test/migration_test.dart` on how to use the generated verification code.

## Workflow

### Schema changes

After adapting a schema and incrementing the `schemaVersion` in the database, run

```
dart run drift_dev schema dump lib/database.dart moor_migrations/moor_schema_v2.json
```

Replace `_v2` with the current `schemaVersion`.

### Generating test code

Run

```
dart run drift_dev schema generate drift_migrations/ test/generated/ --data-classes --companions
```
