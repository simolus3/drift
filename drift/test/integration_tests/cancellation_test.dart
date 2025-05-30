@Tags(['integration'])
@TestOn('vm')
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/sqlite3/native.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/database_vm.dart';
import 'cancellation_test_support.dart';

void main() {
  preferLocalSqlite3();
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

      final db = EmptyDb(await isolate.connect());
      await runTest(db);
    });
  }, skip: 'todo: Cancellations are currently broken on Dart 2.15');

  test('can cancel streams synchronously', () async {
    final createdTimers = <Timer>[];

    await runZoned(
      () async {
        final database = TodoDb(DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ));

        await database.todosTable.all().watch().first;
        // This cancels a stream subscription - drift would usually set up a
        // timer to wait for that.
      },
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, duration, f) {
          final timer = parent.createTimer(zone, duration, f);
          createdTimers.add(timer);
          return timer;
        },
      ),
    );

    expect(
        createdTimers,
        everyElement(
            isA<Timer>().having((e) => e.isActive, 'isActive', isFalse)));
  });
}
