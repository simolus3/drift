import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';

Future<DriftSession> openConnection() async {
  return SqliteConnection(sqlite3.openInMemory());
}
