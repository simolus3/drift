import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/converter.dart';
import '../generated/custom_tables.dart';
import '../test_utils/test_utils.dart';

void main() {
  test('Dart queries on views update correctly', () async {
    final db = CustomTablesDb(testInMemoryDatabase());
    addTearDown(db.close);

    final query = StreamQueue(db.select(db.myView).watch());
    await expectLater(query, emits(isEmpty));

    await db.into(db.config).insert(ConfigCompanion.insert(
        configKey: 'another', syncState: const Value(SyncType.synchronized)));

    expect(
      query,
      emits([
        const MyViewData(
          configKey: 'another',
          syncState: SyncType.synchronized,
        ),
      ]),
    );
  });
}
