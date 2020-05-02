## 3.0.0
 
 Generate code for moor 3.0. This most notably includes custom companions and nested result sets.
 See moor's changelog for all the new features.

## 2.4.0

- Support type converters in moor files. You can import the necessary Dart file with a regular `import`
  statement and then use `MAPPED BY ``MyTypeConverter`` ` in a column definition.

## 2.3.1

- CLI/IDE: Fix path resolution on Windows

## 2.3.0

- Support explicit type arguments for queries in moor files. In 
  `foo(:bar AS TEXT, :baz AS INT): SELECT :bar, :baz;`, the column type can now be inferred.
  Previously, the query would fail because of an unknown type.
- Support `CREATE TRIGGER` and `CREATE INDEX` statements in moor files
- Optional new type inference algorithm
- CLI tool to analyze moor projects

## 2.2.0

- Experimental new CLI tool (`pub run moor_generator`). Not useful at the moment
- Support inheritance when defining daos ([#285](https://github.com/simolus3/moor/issues/285))
- Improve robustness and error messages, many bug fixes

## 2.1.1

- Fix a crash when using common table expressions in custom statements
- Don't use a moor specific caching graph across build steps

## 2.1.0

- Accept inheritance in table definitions (e.g. if an abstract class declared as `IntColumn get foo => integer()()`,
  tables inheriting from that class will also have a `foo` column)
- New `use_data_class_name_for_companions` option that will make the name of the companion
  based on the data class name (uses table name by default).
- New `use_column_name_as_json_key_when_defined_in_moor_file` option to use the column name
  instead of the Dart getter name as json key for columns declared in moor files

## 2.0.1

- Escape `\r` characters in generated Dart literals
- Fix for [an analyzer bug on constant expressions](https://dartbug.com/38658) in generated code
- Small adaptions in generated code for moor version 2.0.1

## 2.0.0
- Rewritten generator with looser coupling to the build package
- Implementation of an SQL IDE as analyzer plugin
- Support `sqlparser` 0.3.0 and updated grammar for `moor` files

## 1.7.1
- Drop support for analyzer versions `<0.36.4`. They weren't supported in version 1.7.0 either, but
  the `pubspec.yaml` did not specify this correctly.
- Support for moor version 1.7.1, which contains a fix for integer columns declared as primary key

## 1.7.0
- Support type converters that were introduced in moor 1.7
- Support parsing and generating code for `.moor` files (see [docs](https://moor.simonbinder.eu/docs/using-sql/custom_tables/)).

## 1.6.0+2
- Generate code to expand array variables

_The +1 release has no changes to 1.6.0, there were issues while uploading to pub. +2 fixes
delivers on the promise of supporting the analyze 0.37_

## 1.5.0
- Parse custom queries and write generated mapping code.
- Refactorings and minor improvements in the generator

For more details on the new features, check out changelog of the 
[moor](https://pub.dev/packages/moor#-changelog-tab-) package.

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
- Blob data type
- Generated classes now use lazy getters instead of recalculating fields on each access
- Custom Constraints
- Data classes can be converted from and to json

## 1.1.0
- The generated data classes now implement `toString()`

## 1.0.0
- Initial version of the Moor generator
