import 'package:moor/ffi.dart';
import 'package:moor/src/runtime/query_builder/query_builder.dart' hide isNull;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../data/tables/converter.dart';
import '../data/tables/custom_tables.dart';

void main() {
  late VmDatabase executor;
  late CustomTablesDb db;

  setUp(() {
    executor = VmDatabase.memory();
    db = CustomTablesDb(executor);
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

  group('views', () {
    test('can be selected from', () {
      return expectLater(db.readView().get(), completion(isEmpty));
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
            ReadViewResult(
              row: QueryRow(entry.toColumns(false), db),
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

  final sqliteVersion = sqlite3.version;
  final hasReturning = sqliteVersion.versionNumber > 3035000;

  group('returning', () {
    test('for custom inserts', () async {
      final result = await db.addConfig(
          'key2', 'val', SyncType.locallyCreated, SyncType.locallyCreated);

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
  }, skip: hasReturning ? null : 'RETURNING not supported by current sqlite');
}
