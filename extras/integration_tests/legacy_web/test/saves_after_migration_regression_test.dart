@TestOn('browser')
import 'dart:html';

import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';
import 'package:test/test.dart';

part 'saves_after_migration_regression_test.g.dart';

// This is a regression test for https://github.com/simolus3/drift/issues/273

class Foos extends Table {
  IntColumn get id => integer().autoIncrement()();
}

class Bars extends Table {
  IntColumn get id => integer().autoIncrement()();
}

@DriftDatabase(
  tables: [Foos, Bars],
)
class _FakeDb extends _$_FakeDb {
  @override
  final int schemaVersion;

  _FakeDb(QueryExecutor executor, this.schemaVersion) : super(executor);

  @override
  List<TableInfo<Table, DataClass>> get allTables => [
        foos,
        if (schemaVersion >= 2) bars,
      ];

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onUpgrade: (m, from, to) async {
        await m.createTable(bars);
      });
}

void main() {
  tearDown(() {
    window.localStorage.clear();
  });

  test('saves the database after creating it', () async {
    var db = _FakeDb(WebDatabase('foo'), 1);
    // ensure the database is opened
    await db.customSelect('SELECT 1').get();

    await db.close();
    db = _FakeDb(WebDatabase('foo'), 1);

    await db.select(db.foos).get(); // shouldn't throw, table exists
    await db.close();
  });

  test('saves the database after an update', () async {
    var db = _FakeDb(WebDatabase('foo'), 1);
    await db.customSelect('SELECT 1').get();
    await db.close();

    // run a migration to version 2
    db = _FakeDb(WebDatabase('foo'), 2);
    await db.customSelect('SELECT 1').get();
    await db.close();

    db = _FakeDb(WebDatabase('foo'), 2);
    await db.select(db.bars).get(); // shouldn't throw, table exists
    await db.close();
  });
}
