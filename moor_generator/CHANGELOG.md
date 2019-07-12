## 1.6.0
- Generate code to expand array variables

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