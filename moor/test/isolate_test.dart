@TestOn('vm')
import 'dart:async';
import 'dart:isolate';

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

  test('stream queries across isolates', () async {
    // three isolates:
    // 1. this one, starting a query stream
    // 2. another one running an insert
    // 3. the MoorIsolate executor the other two are connecting to
    final moorIsolate = await MoorIsolate.spawn(_backgroundConnection);

    final receiveDone = ReceivePort();
    final writer = await Isolate.spawn(_writeTodoEntryInBackground,
        _BackgroundEntryMessage(moorIsolate, receiveDone.sendPort));

    final db = TodoDb.connect(await moorIsolate.connect());
    final expectedEntry = const TypeMatcher<TodoEntry>()
        .having((e) => e.content, 'content', 'Hello from background');

    final expectation = expectLater(
      db.select(db.todosTable).watch(),
      // can optionally emit an empty list if this isolate connected before the
      // other one.
      emitsInOrder([
        mayEmit([]),
        [expectedEntry]
      ]),
    );

    await receiveDone.first;
    writer.kill();
    await expectation;
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

Future<void> _writeTodoEntryInBackground(_BackgroundEntryMessage msg) async {
  final connection = await msg.isolate.connect();
  final database = TodoDb.connect(connection);

  await database
      .into(database.todosTable)
      .insert(TodosTableCompanion.insert(content: 'Hello from background'));
  msg.sendDone.send(null);
}

class _BackgroundEntryMessage {
  final MoorIsolate isolate;
  final SendPort sendDone;

  _BackgroundEntryMessage(this.isolate, this.sendDone);
}
