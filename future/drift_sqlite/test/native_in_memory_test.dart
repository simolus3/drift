@TestOn('dart-vm')
library;

import 'package:drift3/drift.dart';
import 'package:drift_sqlite/src/connection/connection.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'connection_testcases.dart';

void main() {
  declareConnectionTests(
    () async => OpenedDriftConnection(
      SqliteConnection(sqlite3.openInMemory()),
      InMemoryStreamQueryStore(),
    ),
  );
}
