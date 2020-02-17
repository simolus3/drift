## 3.0.0-dev

- __Breaking__: `package:moor/moor_web.dart` no longer exports `package:moor/moor.dart`.
- __Breaking__: Remove deprecated members:
  - top-level `and`, `or` and `not` methods. Use the `&`, `|` and `.not()` instead.
  - top-level `year`, `month`, `day`, `hour`, `minute`, `second` methods. 
    Use the extension member on `Expression<DateTime>` instead.
  - `InsertStatement.insertAll` (use batches instead)
  - the `orReplace` boolean parameter on inserts (use `mode: InsertMode.orReplace` instead)
  - remove the top-level `isIn` and `isNotIn` functions
    (use the `.isIn` and `.isNotIn` instance methods instead)
  - `CustomSelectStatement.execute` and `constructFetcher` - use `get()` or `watch()`,
    respectively
- __Breaking__: Remove the second type variable on `Expression` and subclasses.
- __Breaking__: Remove `customSelectStream` from `QueryEngine`. The `customSelect`
  method now returns an `Selectable` (like `customSelectQuery`, which in turn has been deprecated).
- Experimentally support IndexedDB to store sqlite data on the web

## 2.4.0

- Support aggregate expressions and `group by` in the Dart api
- Support type converters in moor files! The [documentation](https://moor.simonbinder.eu/docs/advanced-features/type_converters/)
  has been updated to explain how to use them.
- Support stream queries in transactions ([#356](https://github.com/simolus3/moor/issues/365))
- Support table-valued functions (like `json_each` and `json_tree`) in moor files 
  [#260](https://github.com/simolus3/moor/issues/260).
- Fix a crash when opening a transaction without using it ([#361](https://github.com/simolus3/moor/issues/361))
- New `mapFromCompanion` method in generated tables to convert a `UpdateCompanion` to a model.
- Support generated moor classes in other builders (like `built_value`). Details [in the docs](https://moor.simonbinder.eu/docs/advanced-features/builder_options/)

## 2.3.0

- New `clientDefault` method for columns. It can be used for dynamic defaults that might be different for
  each row. For instance, you can generate a uuid for each row with `text().clientDefault(() => Uuid().v4()();`
- New CLI tool to analyze moor files: Learn more at [https://moor.simonbinder.eu/cli](https://moor.simonbinder.eu/cli)
- Ability to override the default `ValueSerializer` globally by using `moorRuntimeOptions.valueSerializer`.
- Moor files: You can now explicitly declare column types in those cases that the analyzer can't
  infer it:
  ```
  selectVariable(:variable AS TEXT): SELECT :variable;
  ```
- Support for triggers and indices! You can declare them in a `.moor` file with a regular `CREATE TRIGGER`
  or `CREATE INDEX` statement. Both triggers and indices will be created in the default `onCreate` function.
  To create them in `onUpgrade`, use the new `createIndex` and `createTrigger` functions on a `Migrator`.
- Support for moor-file queries that run on initialization ([#280](https://github.com/simolus3/moor/issues/280))
  Declare them like this `@create: INSERT INTO users VALUES ('default', 'user')`
- Support deletes in batches ([#325](https://github.com/simolus3/moor/issues/325))
- Reduce unnecessary queries when a stream is unsubscribed and then re-subscribed ([#329](https://github.com/simolus3/moor/issues/329))
- Experimental new type inference for the sql analyzer. For details, check the
  `use_experimental_inference` [build option](https://moor.simonbinder.eu/docs/advanced-features/builder_options/)
- Web: New `initializer` parameter to create the database when it doesn't exist
  
## 2.2.0

- Support custom expressions for selects in the Dart API:
  ```dart
  final currentBalance = accounts.income - accounts.expenses;
  select(accounts).addColumns([currentBalance]).map((row) {
    Account account = row.readTable(accounts);
    int balanceOfAccount = row.read(currentBalance);
    return ...
  }).get();
  ```
- Support the `json1` and `fts5` extensions! Using them also requires version 2.2 of `moor_generator`
  and they require `moor_ffi`. For details, see the [documentation](https://moor.simonbinder.eu/docs/using-sql/extensions/).
- Standardized behavior of batches in transactions across backends
- Introduced `OrderingTerm.asc` and `OrderingTerm.desc` factories to construct ordering terms more
  easily

## 2.1.1

- Fix crash when closing a database with asserts disabled
- Web: Save the database after migrations ran
- Escape column names in insert statements, if necessary

## 2.1.0

- New extension methods to simplify the Dart api!
  - Use `&`, `or` and `.not()` to combine boolean expressions.
    ```dart
    // OLD
    select(animals)..where((a) => and(not(a.isMammal), a.amountOfLegs.equals(4)))
    // NEW:
    select(animals)..where((a) => a.isMammal.not() & a.amountOfLegs.equals(4))
    ```
  - Arithmetic: New `+`, `-`, `*` and `/` operators for int and double sql expressions
  - New `+` operator for string concatenation
- Fix crash when `customStatement` is the first operation used on a database ([#199](https://github.com/simolus3/moor/issues/199))
- Allow transactions inside a `beforeOpen` callback
- New `batch` method on generated databases to execute multiple queries in a single batch
- Experimental support to run moor on a background isolate
- Reduce use of parentheses in SQL code generated at runtime
- Query streams now emit errors that happened while running the query
- Upgraded the sql parser which now supports `WITH` clauses in moor files
- Internal refactorings on the runtime query builder

## 2.0.1

- Introduced `isBetween` and `isBetweenValues` methods for comparable expressions (int, double, datetime)
  to check values for both an upper and lower bound
- Automatically map `BOOLEAN` and `DATETIME` columns declared in a sql file to the appropriate type
  (both used to be `double` before).
- Fix streams not emitting cached data when listening multiple times
- __Breaking__: Remove the type parameter from `Insertable.createCompanion` (it was declared as an
  internal method)
  
__2.0.1+1__: Fix crash when `customStatement` is the first operation used on a database 
([#199](https://github.com/simolus3/moor/issues/199))

## 2.0.0
This is the first major update after the initial release and moor and we have a lot to cover:
`.moor` files can now have their own imports and queries, you can embed Dart in sql queries
using the new templates feature and we have a prototype of a pure-Dart SQL IDE ready.
Finally, we also removed a variety of deprecated features. See the breaking changes
section to learn what components are affected and what alternatives are available.

### New features

#### Updates to the sql parser
`.moor` files were introduced in moor 1.7 as an experimental way to declare tables by using
`CREATE TABLE` statements. In this version, they become stable and support their own import
and query system. This allows you to write queries in their own file:

```sql
CREATE TABLE users (
  id INT NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR NOT NULL
);

findByName: SELECT * FROM users WHERE name LIKE :query;
```
When this file is included from a `@UseMoor` annotation, moor will generate methods to run the
query. Of course, you can also write Dart queries for tables declared in sql:
```dart
Stream<User> loadUserById(int id) {
 return (select(users)..where((u) => u.id.equals(2))).watchSingle();
}
```

Moor files can also import other moor files by using an `import 'other.moor';` statement at the 
top. Then, all tables defined in `other.moor` will also be available to the current file.

Moor takes Dart and SQL interop even further with the new "Dart in SQL templates". You can define
a query like this:
```sql
findDynamic: SELECT * FROM users WHERE $condition;
```

And moor will generate a method `findDynamic(Expression<bool, BoolType> condition)` for you. This
allows you to bind the template with a predicate as complex as you'd like. At the moment, Dart
templates are supported for expressions, `OrderBy`, `OrderingTerm` and `Limit`.

`INSERT` statements can now be used as a compiled statement - both in moor files and
in a `@UseMoor` or `@UseDao` annotation. A new builtin linter will even warn you when you forget
to provide a value for a non-nullable column - right at compile time!

And finally, we now generate better query code when queries only return a single column. Instead of
generating a whole new class for that, we simply return the value directly.

#### Experimental ffi support
We released an experimental version of moor built on top of `dart:ffi`. It works
cross-platform and is much, much faster than `moor_flutter`. It you want to try
it out, read the docs [here](https://moor.simonbinder.eu/docs/other-engines/vm/).

### Minor changes
- a `Constant<String>` can now be written to SQL, it used to throw before. This is useful
  if you need default values for strings columns. This also works for `BLOBS` 
  (`Constant<Uint8List>`).
- new `LazyDatabase` for when you want to construct a database asynchronously (for instance, if
  you first need to find a file before you can open a database).

### Breaking changes
- __THIS LIKELY AFFECTS YOUR APP:__ Removed the `transaction` parameter for callbacks
  in transactions and `beforeOpen` callbacks. So, instead of writing
  ```dart
  transaction((t) async {
    await t.update(table)...;
  });
  ```
  simply write
  ```dart
  transaction(() async {
    await update(table)...;
  });
  ```
  Similarly, instead of using `onOpen: (db, details) async {...}`, use
  `onOpen: (details) async {...}`. You don't have to worry about calling methods on
  your database instead of a transaction objects. They will be delegated automatically.
  
  On a similar note, we also removed the `operateOn` parameter from compiled queries.
- Compiled queries that return only a single column (e.g. `SELECT COUNT(*) FROM users`)
  will just return their value (in this case, an `int`) now. Moor no longer generates a 
  new class in that case.
- Removed `MigrationStrategy.onFinished`. Use `beforeOpen` instead.
- Compiled sql queries starting with an underscore will now generate private match queries.
  Previously, the query `_allUsers` would generate a `watchAllUsers` method, that has been
  adopted to `_watchAllUsers`. The `generate_private_watch_methods` builder option, which
  backported this fix to older versions, has thus been removed.
- Removed `InsertStatement.insertOrReplace`. Use `insert(data, orReplace: true)` instead.
- Removed the diff util and `MoorAnimatedList`. Use a third party library for that.

## 1.7.2
- Fixed a race condition that caused the database to be opened multiple times on slower devices.
  This problem was introduced in `1.7.0` and was causing problems during migrations.

## 1.7.1
- Better documentation on `getSingle` and `watchSingle` for queries.
- Fix `INTEGER NOT NULL PRIMARY KEY` wrongly requiring a value during insert (this never affected
  `AUTOINCREMENT` columns, and only affects columns declared in a `.moor` file)

## 1.7.0
- Support custom columns via type converters. See the [docs](https://moor.simonbinder.eu/type_converters)
for details on how to use this feature.
- Transactions now roll back when not completed successfully, they also rethrow the exception
to make debugging easier.
- New `backends` api, making it easier to write database drivers that work with moor. Apart from
`moor_flutter`, new experimental backends can be checked out from git:
  1. `encrypted_moor`: An encrypted moor database: https://github.com/simolus3/moor/tree/develop/extras/encryption
  2. `moor_mysql`: Work in progress mysql backend for moor. https://github.com/simolus3/moor/tree/develop/extras/mysql
- The compiled sql feature is no longer experimental and will stay stable until a major version bump
- New, experimental support for `.moor` files! Instead of declaring your tables in Dart, you can
  choose to declare them with sql by writing the `CREATE TABLE` statement in a `.moor` file.
  You can then use these tables in the database and with daos by using the `include` parameter
  on `@UseMoor` and `@UseDao`. Again, please notice that this is an experimental api and there
  might be some hiccups. Please report any issues you run into.
## 1.6.0
- Experimental web support! See [the documentation](https://moor.simonbinder.eu/web) for details.
- Make transactions easier to use: Thanks to some Dart async magic, you no longer need to run
  queries on the transaction explicitly. This
  ```dart
  Future deleteCategory(Category category) {
    return transaction((t) async {
      await t.delete(categories).delete(category);
    });
  }
  ```
  is now the same as this (notice how we don't have to use the `t.` in front of the delete)
  ```dart
    Future deleteCategory(Category category) {
      return transaction((t) async {
        await delete(categories).delete(category);
      });
    }
    ```
  This makes it much easier to compose operations by extracting them into methods, as you don't
  have to worry about not using the `t` parameter.
- Moor now provides syntax sugar for list parameters in compiled custom queries
 (`SELECT * FROM entries WHERE id IN ?`)
- Support `COLLATE` expressions.
- Date time columns are now comparable
- The `StringType` now supports arbitrary data from sqlite ([#70](https://github.com/simolus3/moor/pull/70)).
  Thanks, [knaeckeKami](https://github.com/knaeckeKami)!
- Bugfixes related to stream queries and `LIMIT` clauses.

## 1.5.1
- Fixed an issue where transformed streams would not always update
- Emit a `INSERT INTO table DEFAULT VALUES` when appropriate. Moor used to generate invalid sql
before.

## 1.5.0
This version introduces some new concepts and features, which are explained in more detail below. 
Here is a quick overview of the new features:
- More consistent and reliable callbacks for migrations. You can now use `MigrationStrategy.beforeOpen` 
to run queries after migrations, but before fully opening the database. This is useful to initialize data.
- Greatly expanded documentation, introduced additional checks to provide more helpful error messages
- New `getSingle` and `watchSingle` methods on queries: Queries that you know will only
  return one row can now be instructed to return the value directly instead of wrapping it in a list.
- New "update companion" classes to clearly separate between absent values and explicitly setting
values back to null - explained below. 
- Experimental support for compiled sql queries: __Moor can now generate typesafe APIs for
  written sql__. Read on to get started.
  
### Update companions
Newly introduced "Update companions" allow you to insert or update data more precisely than before.
Previously, there was no clear separation between "null" and absent values. For instance, let's
say we had a table "users" that stores an id, a name, and an age. Now, let's say we wanted to set
the age of a user to null without changing its name. Would we use `User(age: null)`? Here,
the `name` column would implicitly be set to null, so we can't cleanly separate that. However,
with `UsersCompanion(age: Value(null))`, we know the difference between `Value(null)` and the 
default `Value.absent()`.
 
Don't worry, all your existing code will continue to work, this change is fully backwards
compatible. You might get analyzer warnings about missing required fields. The migration to
update companions will fix that. Replacing normal classes with their update companions is simple
and the only thing needed to fix that. The [documentation](https://moor.simonbinder.eu/queries/#updates-and-deletes)
has been updated to reflect this. If you have additional questions, feel free to 
[create an issue](https://github.com/simolus3/moor/issues/new).
### Compiled sql queries
Experimental support for compile time custom statements. Sounds super boring, but it
actually gives you a fluent way to write queries in pure sql. The moor generator will figure
out what your queries return and automatically generate the boring mapping part. Head on to
[the documentation](https://moor.simonbinder.eu/queries/custom) to find out how to use this new feature.
  
Please note that this feature is in an experimental state: Expect minor, but breaking changes
in the API and in the generated code. Also, if you run into any issues with this feature, 
[reporting them](https://github.com/simolus3/moor/issues/new) would be super appreciated.

## 1.4.0
- Added the `RealColumn`, which stores floating point values
- Better configuration for the serializer with the `JsonKey` annotation and the ability to
use a custom `ValueSerializer`

## 1.3.0
- Moor now supports table joins
  - Added table aliases
- Default values for columns: Just use the `withDefault` method when declaring a column
  - added expressions that resolve to the current date or time
- Fixed a crash that would occur if the first operation was a transaction
- Better support for custom expressions as part of a regular query
- Faster hashcode implementation in generated data classes

## 1.2.0
- __Breaking__: Generated DAO classes are now called `_$YourNameHere`, it used to
be just `_YourNameHere` (without the dollar sign)
- Blob data type
- `insertOrReplace` method for insert statements
- DAOs can now operate on transactions
- Custom constraints
- Query streams are now cached so that equal queries yield identical streams.
  This can improve performance.

## 1.1.0
- Transactions

## 1.0.0
- Initial version of the Moor library
