@Tags(['integration'])
import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

DatabaseConnection createConnection() {
  var counter = 0;
  final loggedValues = <int>[];

  return DatabaseConnection.fromExecutor(
    NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.createFunction(
          functionName: 'increment_counter',
          function: (args) => counter++,
        );
        rawDb.createFunction(
          functionName: 'get_counter',
          function: (args) => counter,
        );

        rawDb.createFunction(
          functionName: 'log_value',
          function: (args) {
            final value = args.single as int;
            loggedValues.add(value);
            return value;
          },
        );
        rawDb.createFunction(
          functionName: 'get_values',
          function: (args) => loggedValues.join(','),
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
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<void> runTest(EmptyDb db) async {
    String slowQuery(int i) => '''
      with recursive slow(x) as (values(increment_counter()) union all select x+1 from slow where x < 1000000)
      select $i from slow;
    '''; //   ^ to get different `StreamKey`s

    // Avoid delays caused by opening the database to interfere with the
    // cancellation mechanism (we need to react to cancellations quicker if the
    // db is already open, which is what we want to test)
    await db.doWhenOpened((e) {});

    final subscriptions = List.generate(
        4, (i) => db.customSelect(slowQuery(i)).watch().listen(null));
    await pumpEventQueue();
    await Future.wait(subscriptions.map((e) => e.cancel()));

    final amountOfSlowQueries = await db
        .customSelect('select get_counter() r')
        .map((row) => row.read<int>('r'))
        .getSingle();

    // One slow query is ok if the cancellation wasn't quick enough, we just
    // shouldn't run all 4 of them.
    expect(amountOfSlowQueries, isNot(4));
  }

  group('stream queries are aborted on cancellations', () {
    test('on a background isolate', () async {
      final isolate = await DriftIsolate.spawn(createConnection);
      addTearDown(isolate.shutdownAll);

      final db = EmptyDb.connect(await isolate.connect());
      await runTest(db);
    });
  });

  test('together with switchMap', () async {
    String slowQuery(int i) => '''
      with recursive slow(x) as (values(log_value($i)) union all select x+1 from slow where x < 1000000)
      select $i from slow;
    ''';

    final isolate = await DriftIsolate.spawn(createConnection);
    addTearDown(isolate.shutdownAll);

    final db = EmptyDb.connect(await isolate.connect());
    await db.customSelect('select 1').getSingle();

    final filter = BehaviorSubject<int>();
    addTearDown(filter.close);
    filter
        .switchMap((value) => db.customSelect(slowQuery(value)).watch())
        .listen(null);

    for (var i = 0; i < 4; i++) {
      filter.add(i);
      await pumpEventQueue();
    }

    final values = await db
        .customSelect('select get_values() r')
        .map((row) => row.read<String>('r'))
        .getSingle();

    expect(values.split(',').length, lessThan(4), reason: 'Read all $values');
  });
}
