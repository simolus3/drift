Example to demonstrate tests for schema migrations.

See `test/migration_test.dart` on how to use the generated verification code.

## Workflow

### Schema changes

After adapting a schema and incrementing the `schemaVersion` in the database, run

```
dart run drift_dev schema dump lib/database.dart drift_migrations/
```

### Generating test code

Run

```
dart run drift_dev schema generate drift_migrations/ test/generated/ --data-classes --companions
```

Since we're using the step-by-step generator to make writing migrations easier, this command
is used to generate a helper file in `lib/`:

```
dart run drift_dev schema steps drift_migrations/ lib/src/versions.dart
```
