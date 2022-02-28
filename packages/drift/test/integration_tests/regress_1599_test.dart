import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import '../data/tables/converter.dart';
import '../data/tables/custom_tables.dart';

void main() {
  test('Dart queries on views update correctly', () async {
    final db = CustomTablesDb(NativeDatabase.memory());
    addTearDown(db.close);

    expect(
      db.select(db.myView).watch(),
      emitsInOrder([
        isEmpty,
        [MyViewData(configKey: 'another', syncState: SyncType.synchronized)]
      ]),
    );

    await pumpEventQueue();
    await db.into(db.config).insert(ConfigCompanion.insert(
        configKey: 'another', syncState: const Value(SyncType.synchronized)));
  });
}
