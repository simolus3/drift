@TestOn('vm')
library;

import 'package:drift3_preview/drift.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

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
        },
      );
    }
  }
}

final class TestDb extends GeneratedDatabase {
  TestDb() : super(testInMemoryDatabase());

  @override
  final int schemaVersion = 1;
  @override
  DatabaseSchema get schema => DatabaseSchema.empty;
}
