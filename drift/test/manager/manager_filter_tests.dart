import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late TodoDb db;

  setUp(() {
    db = TodoDb(testInMemoryDatabase());
  });

  tearDown(() => db.close());
}
