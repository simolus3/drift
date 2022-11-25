import 'dart:isolate';

import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

part 'regress_2166_test.g.dart';

void main() {
  for (final existingListener in [true, false]) {
    for (final useIsolate in [true, false]) {
      for (final useTransaction in [true, false]) {
        for (final singleClientMode in [true, false]) {
          _defineTest(
              existingListener, useIsolate, useTransaction, singleClientMode);
        }
      }
    }
  }
}

void _defineTest(
  bool existingListener,
  bool useIsolate,
  bool useTransaction,
  bool singleClientMode,
) {
  final vars = 'existingListener=$existingListener, '
      'useIsolate=$useIsolate, '
      'useTransaction=$useTransaction, '
      'singleClientMode=$singleClientMode';

  test('can read-your-writes ($vars)', () async {
    final isolate = useIsolate ? await _spawnIsolate() : null;

    final db = useIsolate
        ? _SomeDb.connect(await isolate!.connect())
        : _SomeDb(NativeDatabase.memory());

    addTearDown(() async {
      await db.close();

      if (!singleClientMode && useIsolate) {
        await isolate!.shutdownAll();
      }
    });

    await db.into(db.someTable).insert(_SomeTableCompanion());

    Stream<_SomeTableData> getRow() => db.select(db.someTable).watchSingle();

    Future<void> readYourWrite() async {
      final update = _SomeTableCompanion(name: Value('x'));
      await db.update(db.someTable).write(update);
      // await pumpEventQueue();
      final row = await getRow().first;
      expect(row.name, equals('x'),
          reason: 'should be able to read the row we just wrote');
    }

    if (existingListener) {
      getRow().listen(null);
    }

    await (useTransaction ? db.transaction(readYourWrite) : readYourWrite());
  });
}

Future<DriftIsolate> _spawnIsolate() async {
  final out = ReceivePort();
  final args = out.sendPort;
  await Isolate.spawn(_isolateEntrypoint, args);
  return (await out.first) as DriftIsolate;
}

void _isolateEntrypoint(SendPort out) {
  final driftIsolate = DriftIsolate.inCurrent(() {
    final driver = NativeDatabase.memory();
    return DatabaseConnection(driver);
  });
  out.send(driftIsolate);
}

class _SomeTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().nullable()();
}

@DriftDatabase(tables: [_SomeTable])
class _SomeDb extends _$_SomeDb {
  _SomeDb(super.executor);

  _SomeDb.connect(DatabaseConnection connection) : super.connect(connection);

  @override
  final schemaVersion = 1;
}
