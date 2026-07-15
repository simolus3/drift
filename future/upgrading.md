# Upgrade notes

Collection of API changes in demo apps to help come up with a migration tool.

## examples/app

- Worker: Replace `WasmDatabase.workerMainForOpen` with `WebSqlite(workerEntrypoint(controller: WasmDatabase.driftDatabaseController())`.
- Changing imports
  - `package:drift/drift.dart` to `package:drift3/drift.dart` (temporary).
- Syntax changes:
  - Remove trailing `()` from columns (doesn't work with `late final` columns).
