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
