import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:test/scaffolding.dart';

// At some point, we should use a `WasmDatabase` here since it was compiled
// in a reasonable way and will be must more reliable than proxying to a VM,
// but this is the easiest setup for now.
DatabaseConnection testInMemoryDatabase() {
  return remote(spawnHybridUri('/test/test_utils/sqlite_server.dart'));
}
