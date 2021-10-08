import 'dart:async';

import 'package:moor/ffi.dart';
import 'package:test/scaffolding.dart';

import '../data/tables/todos.dart';

void main() {
  test('creating a database instance does not schedule async work', () {
    // See https://github.com/simolus3/moor/issues/1235. We shouldn't run async
    // work without users being aware of it, and no one expects creating an
    // instance to schedule new microtasks.
    noAsync(() => TodoDb(VmDatabase.memory()));
  });
}

T noAsync<T>(T Function() fun) {
  return runZoned(
    fun,
    zoneSpecification: ZoneSpecification(
      scheduleMicrotask: (self, parent, zone, function) {
        throw StateError('Not allowed: scheduleMicrotask');
      },
      createTimer: (self, parent, zone, duration, callback) {
        throw StateError('Not allowed: createTimer');
      },
      createPeriodicTimer: (self, parent, zone, duration, callback) {
        throw StateError('Not allowed: createPeriodicTimer');
      },
    ),
  );
}
