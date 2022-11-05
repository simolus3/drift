import 'package:test/test.dart';

import '../../generated/converter.dart';
import '../../generated/custom_tables.dart';
import '../../test_utils/test_utils.dart';

void main() {
  // see ../data/tables/tables.drift
  late MockExecutor mock;
  late CustomTablesDb db;

  setUp(() {
    mock = MockExecutor();
    db = CustomTablesDb(mock);
  });

  tearDown(() => db.close());

  test('isInValues', () async {
    expect(
      db.select(db.config)
        ..where((tbl) => tbl.syncState.isInValues([
              SyncType.synchronized,
              SyncType.locallyCreated,
            ])),
      generates(
          'SELECT * FROM "config" WHERE "sync_state" IN (?, ?) AND "sync_state" IS NOT NULL',
          [
            ConfigTable.$converter0.toSql(SyncType.synchronized),
            ConfigTable.$converter0.toSql(SyncType.locallyCreated),
          ]),
    );
    expect(
      db.select(db.config)
        ..where((tbl) => tbl.syncState.isInValues([
              SyncType.synchronized,
              SyncType.locallyCreated,
              null,
            ])),
      generates(
          'SELECT * FROM "config" WHERE "sync_state" IN (?, ?) OR "sync_state" IS NULL',
          [
            ConfigTable.$converter0.toSql(SyncType.synchronized),
            ConfigTable.$converter0.toSql(SyncType.locallyCreated),
          ]),
    );
  });

  test('isNotInValues', () async {
    expect(
      db.select(db.config)
        ..where((tbl) => tbl.syncState.isNotInValues([
              SyncType.synchronized,
              SyncType.locallyCreated,
            ])),
      generates(
          'SELECT * FROM "config" WHERE "sync_state" NOT IN (?, ?) OR "sync_state" IS NULL',
          [
            ConfigTable.$converter0.toSql(SyncType.synchronized),
            ConfigTable.$converter0.toSql(SyncType.locallyCreated),
          ]),
    );

    expect(
      db.select(db.config)
        ..where((tbl) => tbl.syncState.isNotInValues([
              SyncType.synchronized,
              SyncType.locallyCreated,
              null,
            ])),
      generates(
          'SELECT * FROM "config" WHERE "sync_state" NOT IN (?, ?) AND "sync_state" IS NOT NULL',
          [
            ConfigTable.$converter0.toSql(SyncType.synchronized),
            ConfigTable.$converter0.toSql(SyncType.locallyCreated),
          ]),
    );
  });
}
