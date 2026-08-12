@TestOn('vm')
library;

import 'dart:async';

import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils.dart';

void main() {
  test('can cancel streams synchronously', () async {
    final createdTimers = <Timer>[];

    await runZoned(
      () async {
        final database = TodoDb(
          DriftConnection(
            dialect: SqliteDialect.new,
            openConnection: openInMemoryDatabase,
            closeStreamsSynchronously: true,
          ),
        );

        await database.todosTableQueries.all().watch().first;
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
      everyElement(isA<Timer>().having((e) => e.isActive, 'isActive', isFalse)),
    );
  });
}
