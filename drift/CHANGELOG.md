## 1.1.0-dev

- Add the `references` method to `BuildColumn` to reference a column declared 
  in another Dart table.
- Add the `generateInsertable` option to `@UseRowClass`. When enabled, the generator
  will emit an extension to use the row class as an `Insertable`.
  Thanks to [@westito](https://github.com/westito).
- Allow the generator to emit correct SQL code when using arrays with the
  `new_sql_code_generation` option in specific scenarios.
- Improved support for pausing query stream subscriptions. Instead of buffering events,
  query streams will suspend fetching data if all listeners are paused.

## 1.0.0

- Add `DoUpdate.withExcluded` to refer to the excluded row in an upsert clause.
- Add optional `where` clause to `DoUpdate` constructors

This is the initial release of the `drift` package (formally known as `moor`).
For an overview of old `moor` releases, see its [changelog](https://pub.dev/packages/moor/changelog).
