## 3.0.0

Support `moor` version 3.0. To learn what's new, head over to [its changelog](https://pub.dev/packages/moor).

## 2.1.1

- Fix `runCustom` not using the provided variables ([#406](https://github.com/simolus3/moor/issues/406))

## 2.1.0

- Expose the underlying database from sqflite in `FlutterQueryExecutor`.
  This exists only to make migrations to moor easier.

## 2.0.0
See the changelog of [moor](https://pub.dev/packages/moor#-changelog-tab-) for details,
or check out an overview of new features [here](https://moor.simonbinder.eu/v2)

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
use a custom `ValueSerializer`s

## 1.3.0
- Moor now supports table joins
  - Added table aliases
- Default values for columns: Just use the `withDefault` method when declaring a column
  - added expressions that resolve to the current date or time
- Fixed a crash that would occur if the first operation was a transaction
- Better support for custom expressions as part of a regular query
- Faster hashcode implementation in generated data classes

## 1.2.0
Changes from the moor and moor_generator libraries:
- __Breaking__: Generated DAO classes are now called `_$YourNameHere`, it used to
be just `_YourNameHere` (without the dollar sign)
- Blob data type
- `insertOrReplace` method for insert statements
- DAOs can now operate on transactions
- Custom constraints
- Query streams are now cached so that equal queries yield identical streams.
  This can improve performance.
- Generated classes now use lazy getters instead of recalculating fields on each access
- Data classes can be converted from and to json

## 1.1.0
- Transactions

## 1.0.0
- Initial release
