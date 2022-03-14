## drift_sqflite

`drift_sqflite` contains a drift database implementation based on the `sqflite`
package.

For more information on `drift`, see its [documentation](https://drift.simonbinder.eu/docs/).

### Usage

The `SqfliteQueryExecutor` class can be passed to the constructor of your drift database
class to make it use `sqflite`.

```dart
@DriftDatabase(tables: [Todos, Categories])
class MyDatabase extends _$MyDatabase {
  // we tell the database where to store the data with this constructor
  MyDatabase() : super(_openConnection());

  // you should bump this number whenever you change or add a table definition.
  // Migrations are covered later in the documentation.
  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return SqfliteQueryExecutor.inDatabaseFolder(path: 'db.sqlite');
}
```

__Note__: The `drift_sqflite` package is an alternative to the standard approach suggested in
the drift documentation (which consists of a `NativeDatabase` instead of `SqfliteQueryExecutor`).
Using this package is primarily recommended when migrating existing projects off `moor_flutter`.
When using a `SqfliteQueryExecutor`, you don't need to depend on `sqlite3_flutter_libs` like the
drift documentation suggests for the standard approach.

### Migrating from `moor_flutter`

The easiest way to migrate from `moor_flutter` to `drift_sqflite` is to use the
[automatic migration tool](https://drift.simonbinder.eu/name/#automatic-migration).
