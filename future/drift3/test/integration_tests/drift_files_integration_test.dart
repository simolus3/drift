import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';

import 'package:test/test.dart';

import '../generated/converter.dart';
import '../generated/custom_tables.dart';
import '../test_utils.dart';

void main() {
  late CustomTablesDb db;

  setUp(() {
    db = CustomTablesDb(testInMemoryDatabase());
  });

  tearDown(() => db.close());

  test('can create everything', () async {
    // Good enough if it doesn't throw, we're talking to a real database
    await db.initialize();
  });

  test('can use nullable columns', () async {
    await db.delete(db.config).go();
    await expectLater(db.nullableQuery().getSingle(), completion(isNull));
  });

  test('can select to existing data classes', () async {
    await db
        .into(db.noIds)
        .insert(NoIdsCompanion.insert(payload: Uint8List(12)));
    final result = await db.select(db.noIds).getSingle();
    expect(result.payload, hasLength(12));
  });

  test('updates for tables introduced in Dart subquery', () async {
    await db
        .into(db.config)
        .insert(ConfigCompanion.insert(configKey: 'my_key'));

    final inner = db.selectOnly(db.mytable)..addColumns([db.mytable.sometext]);
    final stream = StreamQueue(
      db
          .readDynamic(predicate: (config) => config.configKey.isInQuery(inner))
          .watch(),
    );

    await expectLater(stream, emits(isEmpty));
    await db
        .into(db.mytable)
        .insert(MytableCompanion.insert(sometext: const Value('my_key')));
    await expectLater(stream, emits(hasLength(1)));
    await stream.cancel();
  });

  group('views', () {
    test('can be selected from', () {
      return expectLater(db.readView().get(), completion(isEmpty));
    });

    test('can be selected from with predicates', () async {
      await db
          .update(db.config)
          .write(
            const ConfigCompanion(
              configKey: Value('k'),
              syncState: Value(SyncType.synchronized),
            ),
          );

      var rows = await db
          .readView(where: (v) => v.configKey.length.isGreaterOrEqualValue(3))
          .get();
      expect(rows, isEmpty);

      await db
          .update(db.config)
          .write(const ConfigCompanion(configKey: Value('key')));
      rows = await db
          .readView(where: (v) => v.configKey.length.isGreaterOrEqualValue(3))
          .get();
      expect(rows, isNotEmpty);
    });

    test('can be selected from dart', () async {
      await db
          .update(db.config)
          .write(
            const ConfigCompanion(syncState: Value(SyncType.synchronized)),
          );
      await db
          .into(db.config)
          .insert(ConfigCompanion.insert(configKey: 'not_in_view'));

      final row = await db.select(db.myView).getSingle();
      expect(row.configKey, 'key');
    });

    test('can be used in a query stream', () async {
      final stream = StreamQueue(db.readView().watch());
      addTearDown(stream.cancel);
      const entry = Config(
        configKey: 'another_key',
        configValue: DriftAny('value'),
        syncState: SyncType.synchronized,
        syncStateImplicit: SyncType.synchronized,
      );

      await expectLater(stream, emits(isEmpty));

      final expectation = expectLater(
        stream,
        emits([
          MyViewData(
            configKey: entry.configKey,
            configValue: entry.configValue,
            syncState: entry.syncState,
            syncStateImplicit: entry.syncStateImplicit,
          ),
        ]),
      );

      await db.into(db.config).insert(entry);
      await expectation;
    });
  });

  test('LIST queries integration test', () async {
    final first = await db.withDefaultsQueries.insertReturning(
      WithDefaultsCompanion.insert(a: const Value('foo'), b: const Value(1)),
    );
    final second = await db.withDefaultsQueries.insertReturning(
      WithDefaultsCompanion.insert(a: const Value('foo'), b: const Value(2)),
    );

    await db.withConstraintsQueries.insertOne(
      WithConstraintsCompanion.insert(b: 1),
    );
    await db.withConstraintsQueries.insertOne(
      WithConstraintsCompanion.insert(b: 1),
    );
    await db.withConstraintsQueries.insertOne(
      WithConstraintsCompanion.insert(b: 2),
    );

    final nested = await db.nested('foo').get();
    expect(nested, hasLength(2));

    expect(
      nested,
      contains(
        isA<NestedResult>()
            .having((e) => e.defaults, 'defaults', first)
            .having((e) => e.nestedQuery1, 'nested', hasLength(2)),
      ),
    );

    expect(
      nested,
      contains(
        isA<NestedResult>()
            .having((e) => e.defaults, 'defaults', second)
            .having((e) => e.nestedQuery1, 'nested', hasLength(1)),
      ),
    );
  });

  test('insert with explicit rowid', () async {
    await db.withConstraintsQueries.insertOne(
      WithConstraintsCompanion.insert(b: 1, rowid: Value(12)),
    );
    final row = await db.select(db.withConstraints).addColumns([
      db.withConstraints.rowId,
    ]).getSingle();

    expect(row.read(db.withConstraints.rowId), 12);
    expect(row.readTable(db.withConstraints), WithConstraint(b: 1));
  });

  group('returning', () {
    test('for custom inserts', () async {
      final result = await db.addConfig(
        value: ConfigCompanion.insert(
          configKey: 'key2',
          configValue: const Value(DriftAny('val')),
          syncState: const Value(SyncType.locallyCreated),
          syncStateImplicit: const Value(SyncType.locallyCreated),
        ),
      );

      expect(result, hasLength(1));
      expect(
        result.single,
        const Config(
          configKey: 'key2',
          configValue: DriftAny('val'),
          syncState: SyncType.locallyCreated,
          syncStateImplicit: SyncType.locallyCreated,
        ),
      );
    });
  });

  test('can run query with custom result set', () async {
    await db.withConstraintsQueries.insertOne(
      WithConstraintsCompanion.insert(b: 1, a: Value('key')),
    );
    await db.noIdsQueries.insertOne(
      NoIdsCompanion.insert(payload: Uint8List(512)),
    );

    final result = await db.customResult().get();
    expect(result, hasLength(1));

    final row = result.single;
    expect(row.b, 1);
    expect(row.syncState, isNull);
    expect(
      row.config,
      Config(configKey: 'key', configValue: DriftAny('values')),
    );
    expect(
      row.noIds,
      isA<NoIdRow>().having((e) => e.payload, 'payload', hasLength(512)),
    );
    expect(row.nested, hasLength(1));
  });

  test('can run updateQuery with Insertable', () async {
    await db.addConfig(
      value: ConfigCompanion.insert(
        configKey: 'updateKey',
        configValue: Value(DriftAny(1)),
        syncState: Value(null),
        syncStateImplicit: Value(null),
      ),
    );
    await db.updateAll(
      all: ConfigCompanion(
        configValue: Value(DriftAny(2)),
        syncState: Value(SyncType.locallyCreated),
      ),
      key: (config) => config.configKey.equals('updateKey'),
    );

    final config = await db.readConfig('updateKey').getSingle();

    expect(
      config,
      Config(
        configKey: 'updateKey',
        configValue: DriftAny(2),
        syncState: SyncType.locallyCreated,
      ),
    );
  });
}
