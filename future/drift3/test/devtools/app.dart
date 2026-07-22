import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';

import '../generated/todos.dart';

void main() {
  TodoDb(
    DriftConnection(
      dialect: SqliteDialect.new,
      openConnection: () async => SqliteConnection(sqlite3.openInMemory()),
    ),
  );
  print('database created');

  // Keep the process alive
  Stream<void>.periodic(const Duration(seconds: 10)).listen(null);
}
