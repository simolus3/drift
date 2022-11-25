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
        final vars = 'existingListener=$existingListener, '
            'useIsolate=$useIsolate, '
            'useTransaction=$useTransaction';

        test('can read-your-writes ($vars)', () async {
          final db = useIsolate
              ? _SomeDb.connect(await _connect())
              : _SomeDb(NativeDatabase.memory());

          addTearDown(db.close);

          await db.into(db.someTable).insert(_SomeTableCompanion());

          Stream<_SomeTableData> getRow() =>
              db.select(db.someTable).watchSingle();

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

          await (useTransaction
              ? db.transaction(readYourWrite)
              : readYourWrite());
        });
      }
    }
  }
}

Future<DatabaseConnection> _connect() async {
  final out = ReceivePort();
  final args = out.sendPort;
  await Isolate.spawn(_isolateEntrypoint, args);
  final isolate = (await out.first) as DriftIsolate;
  return isolate.connect();
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
