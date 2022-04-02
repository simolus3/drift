import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:test/scaffolding.dart';

DatabaseConnection testInMemoryDatabase() {
  return remote(spawnHybridUri('/test/test_utils/sqlite_server.dart'));
}
