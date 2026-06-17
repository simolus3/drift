/// @docImport '../native.dart';
/// @docImport 'package:drift3/drift.dart';
library;

/// How a [sqliteConnectionPool] should interact with watched queries in drift.
///
/// The default and recommended option is [native], which uses native SQLite
/// update hooks to ensure drift streams only emit updates for writes that
/// actually happened. However, [native] misses updates for `WITHOUT ROWID`
/// tables and custom updates added via
/// [DatabaseConnectionUser.markTablesUpdated]. To rely on this feature, use
/// the [drift] mode instead.
enum UpdateNotificationMode {
  /// Use SQLite update hooks to track which tables were affected by a
  /// statement.
  native,

  /// Disable SQLite update hooks and process updates entirely in Dart.
  drift,
}
