import 'dart:ffi';

import 'package:sqlite3/sqlite3.dart';

/// This entire file is an elaborate hack to workaround https://github.com/simolus3/drift/issues/835.
///
/// Users were running into database deadlocks after (stateless) hot restarts
/// in Flutter when they use transactions. The problem is that we don't have a
/// chance to call `sqlite3_close` before a Dart VM restart, the Dart object is
/// just gone without a trace. This means that we're leaking sqlite3 database
/// connections on restarts.
/// Even worse, those connections might have a lock on the database, for
/// instance if they just started a transaction.
///
/// Our solution is to store open sqlite3 database connections in an in-memory
/// sqlite database which can survive restarts! For now, we keep track of the
/// pointer of an sqlite3 database handle in that database.
/// At an early stage of their `main()` method, users can now use
/// `VmDatabase.closeExistingInstances()` to release those resources.
final DatabaseTracker tracker = DatabaseTracker();

/// Internal class that we don't export to drift users. See [tracker] for why
/// this is necessary.
class DatabaseTracker {
  final Database _db;

  /// Creates a new tracker with necessary tables.
  DatabaseTracker()
      : _db = sqlite3.open(
          'file:drift_connection_store?mode=memory&cache=shared',
          uri: true,
        ) {
    _db.execute('''
CREATE TABLE IF NOT EXISTS open_connections(
  database_pointer INTEGER NOT NULL PRIMARY KEY,
  path TEXT NULL
);
    ''');
  }

  /// Tracks the [openedDb]. The [path] argument can be used to track the path
  /// of that database, if it's bound to a file.
  void markOpened(String path, Database openedDb) {
    final stmt = _db.prepare('INSERT INTO open_connections VALUES (?, ?)');
    stmt.execute([openedDb.handle.address, path]);
    stmt.dispose();
  }

  /// Marks the database [db] as closed.
  void markClosed(Database db) {
    final ptr = db.handle.address;
    _db.execute('DELETE FROM open_connections WHERE database_pointer = $ptr');
  }

  /// Closes tracked database connections.
  void closeExisting() {
    _db.execute('BEGIN;');

    try {
      final results =
          _db.select('SELECT database_pointer FROM open_connections');

      for (final row in results) {
        final ptr = Pointer.fromAddress(row.columnAt(0) as int);
        sqlite3.fromPointer(ptr).dispose();
      }

      _db.execute('DELETE FROM open_connections;');
    } finally {
      _db.execute('COMMIT;');
    }
  }
}
