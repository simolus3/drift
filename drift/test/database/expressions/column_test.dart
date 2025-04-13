import 'package:test/test.dart';

import '../../generated/converter.dart';
import '../../generated/custom_tables.dart';
import '../../test_utils/test_utils.dart';

void main() {
  // see ../data/tables/tables.drift
  late MockSession session;
  late CustomTablesDb db;

  setUp(() {
    session = MockSession();
    db = CustomTablesDb(createConnection(session));
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
          contains(
              'FROM "config" WHERE "sync_state" IN (?1,?2) AND "sync_state" IS NOT NULL;'),
          [
            ConfigTable.$convertersyncState.toSql(SyncType.synchronized),
            ConfigTable.$convertersyncState.toSql(SyncType.locallyCreated),
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
          contains(
              'FROM "config" WHERE "sync_state" IN (?1,?2) OR "sync_state" IS NULL;'),
          [
            ConfigTable.$convertersyncState.toSql(SyncType.synchronized),
            ConfigTable.$convertersyncState.toSql(SyncType.locallyCreated),
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
          contains(
              'FROM "config" WHERE "sync_state" NOT IN (?1,?2) OR "sync_state" IS NULL'),
          [
            ConfigTable.$convertersyncState.toSql(SyncType.synchronized),
            ConfigTable.$convertersyncState.toSql(SyncType.locallyCreated),
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
          contains(
              'FROM "config" WHERE "sync_state" NOT IN (?1,?2) AND "sync_state" IS NOT NULL;'),
          [
            ConfigTable.$convertersyncState.toSql(SyncType.synchronized),
            ConfigTable.$convertersyncState.toSql(SyncType.locallyCreated),
          ]),
    );
  });
}
