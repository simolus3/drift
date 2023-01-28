import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/converter.dart';
import '../generated/custom_tables.dart';
import '../test_utils/test_utils.dart';

void main() {
  test('Dart queries on views update correctly', () async {
    final db = CustomTablesDb(testInMemoryDatabase());
    addTearDown(db.close);

    expect(
      db.select(db.myView).watch(),
      emitsInOrder([
        isEmpty,
        [
          const MyViewData(
            configKey: 'another',
            syncState: SyncType.synchronized,
          ),
        ]
      ]),
    );

    await pumpEventQueue();
    await db.into(db.config).insert(ConfigCompanion.insert(
        configKey: 'another', syncState: const Value(SyncType.synchronized)));
  });
}
