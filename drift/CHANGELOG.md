## 1.1.0-dev

- Add the `references` method to `BuildColumn` to reference a column declared 
  in another Dart table.
- Allow the generator to emit correct SQL code when using arrays with the
  `new_sql_code_generation` option in specific scenarios.

## 1.0.0

- Add `DoUpdate.withExcluded` to refer to the excluded row in an upsert clause.
- Add optional `where` clause to `DoUpdate` constructors

This is the initial release of the `drift` package (formally known as `moor`).
For an overview of old `moor` releases, see its [changelog](https://pub.dev/packages/moor/changelog).
