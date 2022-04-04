import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

Version get sqlite3Version {
  return sqlite3.version;
}

DatabaseConnection testInMemoryDatabase() {
  return DatabaseConnection.fromExecutor(NativeDatabase.memory());
}
