@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  for (final suspendBetweenListeners in [true, false]) {
    for (final asyncMap in [true, false]) {
      test(
          'suspendBetweenListeners=$suspendBetweenListeners, asyncMap=$asyncMap',
          () async {
        final db = TestDb();
        final select = db.customSelect('select 1');
        final stream = asyncMap
            ? select.asyncMap(Future.value).watch()
            : select.map((row) => row).watch();

        final log = <Object>[];
        stream.listen(log.add);
        if (suspendBetweenListeners) await pumpEventQueue();
        stream.listen(log.add);
        await pumpEventQueue();
        expect(log, hasLength(2));
      });
    }
  }
}

class TestDb extends GeneratedDatabase {
  TestDb() : super(NativeDatabase.memory());
  @override
  final List<TableInfo> allTables = const [];
  @override
  final int schemaVersion = 1;
}
