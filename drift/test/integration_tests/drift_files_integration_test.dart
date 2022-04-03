@TestOn('vm') // because of skips.dart
import 'package:drift/drift.dart' hide isNull;

import 'package:test/test.dart';

import '../data/tables/converter.dart';
import '../data/tables/custom_tables.dart';
import '../skips.dart';
import '../test_utils/test_utils.dart';

void main() {
  late CustomTablesDb db;

  setUp(() {
    db = CustomTablesDb.connect(testInMemoryDatabase());
  });

  tearDown(() => db.close());

  test('can create everything', () async {
    // Good enough if it doesn't throw, we're talking to a real database
    await db.doWhenOpened((e) => null);
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
    final stream = db
        .readDynamic(predicate: (config) => config.configKey.isInQuery(inner))
        .watch();

    expect(stream, emitsInOrder([isEmpty, hasLength(1)]));

    await db
        .into(db.mytable)
        .insert(MytableCompanion.insert(sometext: const Value('my_key')));
  });

  group('views', () {
    test('can be selected from', () {
      return expectLater(db.readView().get(), completion(isEmpty));
    });

    test('can be selected from dart', () async {
      await db.update(db.config).write(
          const ConfigCompanion(syncState: Value(SyncType.synchronized)));
      await db
          .into(db.config)
          .insert(ConfigCompanion.insert(configKey: 'not_in_view'));

      final row = await db.select(db.myView).getSingle();
      expect(row.configKey, 'key');
    });

    test('can be used in a query stream', () async {
      final stream = db.readView().watch();
      final entry = Config(
        configKey: 'another_key',
        configValue: 'value',
        syncState: SyncType.synchronized,
        syncStateImplicit: SyncType.synchronized,
      );

      final expectation = expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          [
            MyViewData(
              configKey: entry.configKey,
              configValue: entry.configValue,
              syncState: entry.syncState,
              syncStateImplicit: entry.syncStateImplicit,
            ),
          ],
        ]),
      );

      await db.into(db.config).insert(entry);
      await expectation;
    });
  });

  test('LIST queries integration test', () async {
    final first = await db.withDefaults.insertReturning(
        WithDefaultsCompanion.insert(a: const Value('foo'), b: const Value(1)));
    final second = await db.withDefaults.insertReturning(
        WithDefaultsCompanion.insert(a: const Value('foo'), b: const Value(2)));

    await db.withConstraints.insertOne(WithConstraintsCompanion.insert(b: 1));
    await db.withConstraints.insertOne(WithConstraintsCompanion.insert(b: 1));
    await db.withConstraints.insertOne(WithConstraintsCompanion.insert(b: 2));

    final nested = await db.nested('foo').get();
    expect(nested, hasLength(2));

    expect(
      nested,
      contains(
        isA<NestedResult>()
            .having((e) => e.defaults, 'defaults', first)
            .having((e) => e.nestedQuery0, 'nested', hasLength(2)),
      ),
    );

    expect(
      nested,
      contains(
        isA<NestedResult>()
            .having((e) => e.defaults, 'defaults', second)
            .having((e) => e.nestedQuery0, 'nested', hasLength(1)),
      ),
    );
  });

  group('returning', () {
    test('for custom inserts', () async {
      final result = await db.addConfig(
          value: ConfigCompanion.insert(
        configKey: 'key2',
        configValue: const Value('val'),
        syncState: const Value(SyncType.locallyCreated),
        syncStateImplicit: const Value(SyncType.locallyCreated),
      ));

      expect(result, hasLength(1));
      expect(
        result.single,
        Config(
          configKey: 'key2',
          configValue: 'val',
          syncState: SyncType.locallyCreated,
          syncStateImplicit: SyncType.locallyCreated,
        ),
      );
    });
  }, skip: ifOlderThanSqlite335());
}
