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