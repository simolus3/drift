import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';

Object? transportRoundtrip(Object? source) {
  return source;
}

Version get sqlite3Version {
  return sqlite3.version;
}

DriftConnection testInMemoryDatabase([DriftDialectFactory? dialect]) {
  final resolvedDialect = dialect ?? SqliteDialect.new;

  return DriftConnection(
    dialect: resolvedDialect,
    openConnection: openInMemoryDatabase,
  );
}

Future<DriftSession> openInMemoryDatabase() async {
  return SqliteConnection(sqlite3.openInMemory());
}
