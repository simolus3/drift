@TestOn('vm')
library;

import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;
import 'package:test/test.dart';

import '../test_utils.dart';

part 'regress_2166_test.g.dart';

void main() {
  for (final existingListener in [true, false]) {
    for (final useIsolate in [true, false]) {
      for (final useTransaction in [true, false]) {
        for (final singleClientMode in [true, false]) {
          _defineTest(
            existingListener,
            useIsolate,
            useTransaction,
            singleClientMode,
          );
        }
      }
    }
  }
}

void _defineTest(
  bool existingListener,
  bool usePool,
  bool useTransaction,
  bool singleClientMode,
) {
  final vars =
      'existingListener=$existingListener, '
      'usePool=$usePool, '
      'useTransaction=$useTransaction, '
      'singleClientMode=$singleClientMode';

  test('can read-your-writes ($vars)', () async {
    final db = usePool
        ? _SomeDb(
            DriftConnection(
              dialect: SqliteDialect.new,
              openConnection: () async =>
                  SqliteConnection(sqlite3.openInMemory()),
            ),
          )
        : _SomeDb(testInMemoryDatabase());

    addTearDown(() async {
      await db.close();
    });

    await db.into(db.someTable).insert(SomeTableCompanion());

    Stream<SomeTableData> getRow() => db.select(db.someTable).watchSingle();

    Future<void> readYourWrite() async {
      final update = SomeTableCompanion(name: Value('x'));
      await db.update(db.someTable).write(update);
      // await pumpEventQueue();
      final row = await getRow().first;
      expect(
        row.name,
        equals('x'),
        reason: 'should be able to read the row we just wrote',
      );
    }

    if (existingListener) {
      getRow().listen(null);
    }

    await (useTransaction ? db.transaction(readYourWrite) : readYourWrite());
  });
}

class SomeTable extends Table {
  IntColumn get id => integer().autoIncrement();

  TextColumn get name => text().nullable();
}

@DriftDatabase(tables: [SomeTable])
final class _SomeDb extends _$_SomeDb {
  _SomeDb(super.executor);

  @override
  final schemaVersion = 1;
}
