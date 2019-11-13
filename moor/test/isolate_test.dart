import 'dart:async';

import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';

void main() {
  // Using the MoorIsolate apis without actually running on a background isolate
  // is pointless, but we can't collect coverage for background isolates:
  // https://github.com/dart-lang/test/issues/1108
  group('in same isolate', () {
    MoorIsolate spawnInSame() {
      return MoorIsolate.inCurrent(_backgroundConnection);
    }

    _runTests(spawnInSame, false);
  });

  group('in background isolate', () {
    Future<MoorIsolate> spawnBackground() {
      return MoorIsolate.spawn(_backgroundConnection);
    }

    _runTests(spawnBackground, true);
  });
}

void _runTests(
    FutureOr<MoorIsolate> Function() spawner, bool terminateIsolate) {
  MoorIsolate isolate;
  DatabaseConnection isolateConnection;

  setUp(() async {
    isolate = await spawner();
    isolateConnection = await isolate.connect(isolateDebugLog: false);
  });

  tearDown(() {
    isolateConnection.executor.close();

    if (terminateIsolate) {
      return isolate.shutdownAll();
    } else {
      return Future.value();
    }
  });

  test('can open database and send requests', () async {
    final database = TodoDb.connect(isolateConnection);

    final result = await database.select(database.todosTable).get();
    expect(result, isEmpty);
  });

  test('stream queries work as expected', () async {
    final database = TodoDb.connect(isolateConnection);
    final initialCompanion = TodosTableCompanion.insert(content: 'my content');

    final stream = database.select(database.todosTable).watchSingle();
    final expectation = expectLater(
      stream,
      emitsInOrder([null, TodoEntry(id: 1, content: 'my content')]),
    );

    await database.into(database.todosTable).insert(initialCompanion);
    await expectation;
  });

  test('can start transactions', () async {
    final database = TodoDb.connect(isolateConnection);
    final initialCompanion = TodosTableCompanion.insert(content: 'my content');

    await database.transaction(() async {
      await database.into(database.todosTable).insert(initialCompanion);
    });

    final result = await database.select(database.todosTable).get();
    expect(result, isNotEmpty);
  });
}

DatabaseConnection _backgroundConnection() {
  return DatabaseConnection.fromExecutor(VmDatabase.memory());
}
