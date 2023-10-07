## 2.13.0-dev

- Add APIs to setup Wasm databases with custom drift workers.
- Add support for [custom types](https://drift.simonbinder.eu/docs/sql-api/types/),
  which are useful when extending drift to support other database engines.
- Add `Expression.and` and `Expression.or` to create disjunctions and conjunctions
  of sub-predicates.
- Step-by-step migrations now save the intermediate schema version after each step.

## 2.12.1

- Fix `readWithConverter` throwing an exception for null values in non-
  nullable columns.

## 2.12.0

- Add support for table-valued functions in the Dart query builder.
- Add the `@TableIndex` annotation for table classes to add an index to the
  table.
- Support `json_each` and `json_tree`.
- Add the `TypeConverter.json` method to define type converters storing JSON
  values more easily.
- Add `TypedResult.readWithConverter` to read a column with a type converter
  from a join result row.

## 2.11.1

- Allow using `.read()` for a column added to a join from the table, fixing a
  regression in drift 2.11.0.
- Make step-by-step migrations easier to customize with `Migrator.runMigrationSteps`.

## 2.11.0

- Add support for subqueries in the Dart query builder.
- Add `isInExp` and `isNotInExp` to construct `IS IN` expressions with arbitrary
  expressions.
- Add the `substr` extension on `Expression<String>` to call the sqlite3 function from
  the Dart API.
- Add `isolateSetup` to `NativeDatabase.createInBackground()` to override native libraries
  or perform other database-unrelated setup work.
- Add `WasmDatabase.probe()`, a method probing for available implementations and existing
  databases on the web without opening one directly.

## 2.10.0

- Adds the `schema steps` command to `drift_dev`. It generates an API making it
  easier to write safe schema migrations ([docs](https://drift.simonbinder.eu/docs/advanced-features/migrations/#step-by-step)).
- Fix drift WASM not being unusable after a previous database implementation becomes
  unavailable in the browser.

## 2.9.0

- Forbid `schemaVersion` returning `0`, as this causes issues in the migrator.
- Drift web support is now stable! By using a `WasmDatabase.open` factory as
  described in https://drift.simonbinder.eu/web/, you can run a drift database
  in modern browsers!

## 2.8.2

- Fix prepared statements leaking when the statement cache is disabled.
- Disable prepared statement caching by default.

## 2.8.1

- Performance improvement: Cache and re-use prepared statements - thanks to [@davidmartos96](https://github.com/davidmartos96/)
- Fix a deadlock after rolling back a transaction in a remote isolate.
- Remove unintended log messages when using `connectToDriftWorker`.

## 2.8.0

- Don't keep databases in an unusable state if the `setup` callback throws an
  exception. Instead, drift will retry the next time the database is used.
- Allow targeting partial indices in `DoUpdate` ([#2394](https://github.com/simolus3/drift/issues/2394))
- Fix deadlocks when `computeWithDatabase` is called inside a `transaction()`.

## 2.7.0

- Add support for `CASE` expressions without a base in the Dart API with the
  `CaseWhenExpression` class.
- Add the new `package:drift/web/workers.dart` library which makes it easier to
  create web workers for drift.

## 2.6.0

- Add `insertReturningOrNull` for potentially empty inserts.
- Add `insertFromSelect` to `InsertStatement` to run `INSERT INTO SELECT`
  statements.
- Add `rowid` parameter to companions for tables with rowids that don't have a
  visible alias for the rowid.
- After opening a database with a higher schema version than the current one set
  in the database class, the schema version in the database will now be downgraded.
- When using a drift isolate in the same engine group, errors on the remote end are
  reported directly instead of wrapping them in a `DriftRemoteException`.
- Added support for `DO NOTHING` during upsert operations with constraint violations

## 2.5.0

- Add `isExp`, `isValue`, `isNotExp` and `isNotValue` methods to `Expression`
  to generate the `IS` operator in SQL.
- Add `all()` extension on tables and views to quickly query all rows.
- Add `serializableConnection()` and `computeWithDatabase()` as extensions on
  databases. The methods allow sharing any drift database between isolates,
  regardless of how the database has been set up.
- The `DatabaseConnection` class now implements `QueryExecutor`, meaning that
  you no longer need a special `.connect()` constructor to use it.

## 2.4.2

- Fix an exception when a client disconnects from a drift remote server while
  processing a pending table update.

## 2.4.1

- Fix `DriftIsolate` leaking resources for closed connections.

## 2.4.0

- Add `textEnum` column builder and `EnumNameConverter` to be able to store enum
  values as string.
- Add `updates` parameter to `Batch.customStatement` - it can be used to specify
  which tables are affected by the custom statement.
- For `STRICT` tables in drift files declaring a `ANY` column, drift will now
  generate a mapping to the new `DriftAny` type.
- Add `likeExp` to generate `LIKE` expression with any comparison expression.
- Fix `UNIQUE` keys declared in drift files being written twice.
- Fix `customConstraints` not appearing in dumped database schema files.
- Lazily load columns in `TypedResult.read`, increasing performance for joins
  with lots of tables or columns.
- Work-around an issue causing complex migrations via `Migrator.alterTable` not to
  work if a view referenced the altered table.

## 2.3.0

- Add the `JsonTypeConverter2` mixin. It behaves similar to the existing json
  type converters, but can use a different SQL and JSON type.
- Add `isInValues` and `isNotInValues` methods to columns with type converters.
  They can be used to compare the column against a list of Dart expressions that
  will be mapped through a type converter.
- Add `TableStatements.insertAll` to atomically insert multiple rows.
- Add `singleClientMode` to `remote()` and `DriftIsolate` connections to make
  the common case with one client more efficient.
- Fix a concurrency issue around transactions.
- Add `NativeDatabase.createInBackground` as a drop-in replacement for
  `NativeDatabase`. It creates a drift isolate behind the scenes, avoiding all
  of the boilerplate usually involved with drift isolates.
- __Experimental__: Add a [modular generation mode](https://drift.simonbinder.eu/docs/advanced-features/builder_options/#enabling-modular-code-generation)
  in which drift will generate multiple smaller files instead of one very large
  one with all tables and generated queries.

## 2.2.0

- Always escape column names, avoiding the costs of using a regular expression
  to check whether they need to be escaped.
- Add extensions for binary methods on integer expressions: `operator ~`,
  `bitwiseAnd` and `bitwiseOr`.

## 2.1.0

- Improve stack traces when using `watchSingle()` with a stream emitting a non-
  singleton list at some point.
- Add `OrderingTerm.nulls` to control the `NULLS FIRST` or `NULLS LAST` clause
  in Dart.

## 2.0.2+1

- Revert the breaking change around `QueryRow.read` only returning non-nullable
  values now - it was causing issues with type inference in some cases.

## 2.0.1

- Fix an error when inserting a null value into a nullable column defined with
  additional checks in Dart.

## 2.0.0

💡: More information on how to migrate is available in the [documentation](https://drift.simonbinder.eu/docs/upgrading/).

- __Breaking__: Type converters now return the types that they were defined to return
  (instead of the nullable variant of those types like before).
  It is an error to use a non-nullable type converter on a column that is nullable in
  SQL and vice-versa.
- __Breaking__: Mapping methods on type converters are now called `toSql` and `fromSql`.
- __Breaking__: Removed `SqlTypeSystem` and subtypes of `SqlType`:
  - To describe the type a column has, use the `DriftSqlType` enum
  - To map a value from Dart to SQL and vice-versa, use an instance of `SqlTypes`,
    reachable via `database.options.types`.
- __Breaking__: `Expression`s (including `Column`s) always have a non-nullable type
  parameter now. They are implicitly nullable, so `TypedResult.read` now returns a
  nullable value.
- __Breaking__: `QueryRow.read` can only read non-nullable values now. To read nullable
  values, use `readNullable`.
- __Breaking__: Remove the `includeJoinedTableColumns` parameter on `selectOnly()`.
  The method now behaves as if that parameter was turned off. To use columns from a
  joined table, add them with `addColumns`.
- __Breaking__: Remove the `fromData` factory on generated data classes. Use the
  `map` method on tables instead.
- Add support for storing date times as (ISO-8601) strings. For details on how
  to use this, see [the documentation](https://drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/#supported-column-types).
- Consistently handle transaction errors like a failing `BEGIN` or `COMMIT`
  across database implementations.
- Add `writeReturning` to update statements; `deleteReturning` and `goAndReturn`
  to delete statatements.
- Support nested transactions.
- Support custom collations in the query builder API.
- [Custom row classes](https://drift.simonbinder.eu/docs/advanced-features/custom_row_classes/)
  can now be constructed with static methods too.
  These static factories can also be asynchronous.

## 1.7.1

- Fix the `NativeDatabase` not disposing statements if running them threw an
  exception [#1917](https://github.com/simolus3/drift/issues/1917).

## 1.7.0

- Add the `int64()` column builder to store large integers. These integers are
  still stored as 64-bit ints in the database, but represented as a `BigInt` in
  Dart. This enables better web support for integers larger than 2^52.
  More details are in [the documentation](https://drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/#bigint-support).
- Add `filter` and `distinct` support to `groupConcat`.
- Fix a deadlock with the `sqflite`-based implementation if the first operation
  in a `transaction` is a future backed by a query stream.

## 1.6.0

- Add the `unique()` method to columns and the `uniqueKeys` override for tables
  to define unique constraints in Dart tables.
- Add the `check()` method to the Dart column builder to generate `CHECK` column
  constraints.
- Also apply type converters for json serialization and deserialization if they
  mix in `JsonTypeConverter`.
- Add the very experimental `package:drift/wasm.dart` library. It uses WebAssembly
  to access sqlite3 without any external JavaScript libraries, but requires you to
  add a [WebAssembly module](https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3#wasm-web-support)
  to the `web/` folder.
  Please note that this specific library is not subject to semantic versioning
  until it leaves its experimental state. It also isn't suitable for production
  use at the moment.
- Internally use `package:js` to wrap sql.js.

## 1.5.0

- Add `DataClassName.extending` to control the superclass of generated row
  classes.
- Add `setup` parameter to the constructors of `WebDatabase` too.
- Don't write variables for expressions in `CREATE VIEW` statements.
- Improve stack traces for errors on a remote isolate.
- Add `MultiExecutor.withReadPool` constructor to load-balance between multiple
  reading executors. This can be used in a multi-isolate approach if some
  queries are expensive.


## 1.4.0

- Most methods to compose statements are now available as an extension on
  tables. As an alternative to `update(todos).replace(newEntry)`, you can
  now write `todos.replaceOne(newEntry)`.
- Deprecate the `from(table)` API introduced in 1.3.0. Having the methods on
  the table instances turned out to be even easier!
- In drift files, you can now use `LIST(SELECT ...)` as a result column to
  get all results of the inner select as a `List` in the result set.

## 1.3.0

- Add the `from(table)` method to generated databases. It can be used to write
  common queries more concisely.
- Make `groupConcat` nullable in the Dart API.
- Throw an exception in a `NativeDatabase` when multiple statements are run in
  a single call. In previous versions, parts of the SQL string would otherwise
  be ignored.
- Close the underlying database when a drift isolate is shut down.

## 1.2.0

- Properly support stream update queries on views.
- Reading blobs from the database is more lenient now.
- Provide a stack trace when `getSingle()` or `watchSingle()` is used on a
  query emitting more than one row.

## 1.1.1

- Rollback transactions when a commit fails.
- Revert a change from 1.1.0 to stop serializing messages over isolates.
  Instead, please set the `serialize` parameter to `false` on the `DriftIsolate` methods.

## 1.1.0

- Add the `references` method to `BuildColumn` to reference a column declared
  in another Dart table.
- Add the `generateInsertable` option to `@UseRowClass`. When enabled, the generator
  will emit an extension to use the row class as an `Insertable`.
  Thanks to [@westito](https://github.com/westito).
- Allow the generator to emit correct SQL code when using arrays with the
  `new_sql_code_generation` option in specific scenarios.
- Add support for [strict tables](https://sqlite.org/stricttables.html) in `.drift` files.
- Add the `generatedAs` method to declare generated columns for Dart tables.
- Add `OrderingTerm.random` to fetch rows in a random order.
- Improved support for pausing query stream subscriptions. Instead of buffering events,
  query streams will suspend fetching data if all listeners are paused.
- Drift isolates no longer serialize messages into a primitive format. This will reduce
  the overhead of using isolates with Drift.

## 1.0.1

- Add `DoUpdate.withExcluded` to refer to the excluded row in an upsert clause.
- Add optional `where` clause to `DoUpdate` constructors

This is the initial release of the `drift` package (formally known as `moor`).
For an overview of old `moor` releases, see its [changelog](https://pub.dev/packages/moor/changelog).
