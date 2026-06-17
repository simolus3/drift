## 3.0.0-alpha.0

- Refactor connection management:
  - Remove `QueryExecutor` and `DriftConnection` interfaces. Use `DriftSession` to represent an opened database connection
    and `DriftConnection` for unopened connections.
  - Remove `package:drift/isolate.dart`. Use `sqliteConnectionPool` from `package:drift_sqlite/native.dart`, which is automatically shared across isolates.
- Refactor the query builder:
  - Different dialects are fully supported now, with each dialect being responsible for SQL generation.
  - Remove `CustomSqlType`. Implement `SqlType` and `PhysicalSqlType` instead.
- Batches now report the output of statements ran in them.
- Drift manager is now a standalone package, `drift_manager`.
- Add `TransactionOptions`, which can be used to request read-only transactions.
- `Selectable.watch` now returns a `QueryStream`, which can be used to track which tables it watches.
