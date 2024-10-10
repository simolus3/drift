Example to demonstrate tests for schema migrations.

See `test/migration_test.dart` on how to use the generated verification code.

## Workflow

### Schema changes

After adapting a schema and incrementing the `schemaVersion` in the database, run

```
dart run drift_dev make-migrations
```

### Testing

Write the migration using the step-by-step migration helper.
To verify the migration, run the tests.

```
dart test
```

To test a specific migration, use the `-N` flag with the migration name.

```
dart test -N "v1 to v2"
```