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
    await moorIsolate.shutdownAll();
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

  test('can run beforeOpen', () async {
    var beforeOpenCalled = false;

    final database = TodoDb.connect(isolateConnection);
    database.migration = MigrationStrategy(beforeOpen: (details) async {
      await database.customStatement('PRAGMA foreign_keys = ON');
      beforeOpenCalled = true;
    });

    // run a select statement to verify that the database is open
    await database.customSelectQuery('SELECT 1').get();
    await database.close();
    expect(beforeOpenCalled, isTrue);
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

  test('supports no-op transactions', () async {
    final database = TodoDb.connect(isolateConnection);
    await database.transaction(() {
      return Future.value(null);
    });
    await database.close();
  });

  test('transactions have an isolated view on data', () async {
    // regression test for https://github.com/simolus3/moor/issues/324
    final db = TodoDb.connect(isolateConnection);

    await db
        .customStatement('create table tbl (id integer primary key not null)');

    Future<void> expectRowCount(TodoDb db, int count) async {
      final rows = await db.customSelectQuery('select * from tbl').get();
      expect(rows, hasLength(count));
    }

    final rowInserted = Completer<void>();
    final runTransaction = db.transaction(() async {
      await db.customInsert('insert into tbl default values');
      await expectRowCount(db, 1);
      rowInserted.complete();
      // Hold transaction open for expectRowCount() outside the transaction to
      // finish
      await Future.delayed(const Duration(seconds: 1));
      await db.customStatement('delete from tbl');
      await expectRowCount(db, 0);
    });

    await rowInserted.future;
    await expectRowCount(db, 0);
    await runTransaction; // wait for the transaction to complete

    await db.close();
  });

  test("can't run queries on a closed database", () async {
    final db = TodoDb.connect(isolateConnection);
    await db.customSelectQuery('SELECT 1;').getSingle();

    await db.close();

    await expectLater(
        () => db.customSelectQuery('SELECT 1;').getSingle(), throwsStateError);
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
