## 1.6 (unreleased)
- Web support!
- Date time columns are now comparable
- Make transactions easier to use: Thanks to some Dart async magic, methods called on your
  database object in a transaction callback will automatically be called on the transaction object.
- Support list parameters in compiled custom queries (`SELECT * FROM entries WHERE id IN ?`)

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
