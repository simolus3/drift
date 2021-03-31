@Tags(['integration'])
import 'package:moor/ffi.dart';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:test/test.dart';

DatabaseConnection createConnection() {
  var counter = 0;

  return DatabaseConnection.fromExecutor(
    VmDatabase.memory(
      setup: (rawDb) {
        rawDb.createFunction(
          functionName: 'increment_counter',
          function: (args) => counter++,
        );
        rawDb.createFunction(
          functionName: 'get_counter',
          function: (args) => counter,
        );
      },
    ),
  );
}

class EmptyDb extends GeneratedDatabase {
  EmptyDb.connect(DatabaseConnection c) : super.connect(c);
  @override
  final List<TableInfo> allTables = const [];
  @override
  final int schemaVersion = 1;
}

void main() {
  moorRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  var i = 0;
  String slowQuery() => '''
    with recursive slow(x) as (values(increment_counter()) union all select x+1 from slow where x < 1000000)
    select ${i++} from slow;
  '''; // ^ to get different `StreamKey`s

  Future<void> runTest(EmptyDb db) async {
    // Avoid delays caused by opening the database to interfere with the
    // cancellation mechanism (we need to react to cancellations quicker if the
    // db is already open, which is what we want to test)
    await db.doWhenOpened((e) {});

    final subscriptions = List.generate(
        4, (_) => db.customSelect(slowQuery()).watch().listen(null));
    await Future.wait(subscriptions.map((e) => e.cancel()));

    final amountOfSlowQueries = await db
        .customSelect('select get_counter() r')
        .map((row) => row.read<int>('r'))
        .getSingle();

    // One slow query is ok if the cancellation wasn't quick enough, we just
    // shouldn't run all 4 of them.
    expect(amountOfSlowQueries, anyOf(0, 1));
  }

  group('stream queries are aborted on cancellations', () {
    test('on the same isolate', () async {
      final db = EmptyDb.connect(createConnection());
      await runTest(db);
    });

    test('on a background isolate', () async {
      final isolate = await MoorIsolate.spawn(createConnection);
      addTearDown(isolate.shutdownAll);

      final db = EmptyDb.connect(await isolate.connect());
      await runTest(db);
    });
  });
}
