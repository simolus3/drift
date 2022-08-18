@TestOn('vm')
import 'dart:async';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'generated/todos.dart';
import 'test_utils/test_utils.dart';

void main() {
  // Using the DriftIsolate apis without actually running on a background
  // isolate is pointless, but we can't collect coverage for background
  // isolates: https://github.com/dart-lang/test/issues/1108

  group('in same isolate', () {
    DriftIsolate spawnInSame(bool serialize) {
      return DriftIsolate.inCurrent(_backgroundConnection,
          serialize: serialize);
    }

    group('with explicit serialization', () {
      _runTests(() => spawnInSame(true), false, true);
    });

    group('without explicit serialization', () {
      _runTests(() => spawnInSame(false), false, false);
    });
  });

  group('in background isolate', () {
    Future<DriftIsolate> spawnBackground(bool serialize) {
      return DriftIsolate.spawn(_backgroundConnection, serialize: serialize);
    }

    group('with explicit serialization', () {
      _runTests(() => spawnBackground(true), true, true);
    });

    group('without explicit serialization', () {
      _runTests(() => spawnBackground(false), true, false);
    });
  }, tags: 'background_isolate');

  test('stream queries across isolates', () async {
    // three isolates:
    // 1. this one, starting a query stream
    // 2. another one running an insert
    // 3. the DriftIsolate executor the other two are connecting to
    final driftIsolate = await DriftIsolate.spawn(_backgroundConnection);

    final receiveDone = ReceivePort();
    final writer = await Isolate.spawn(_writeTodoEntryInBackground,
        _BackgroundEntryMessage(driftIsolate, receiveDone.sendPort));

    final db = TodoDb.connect(await driftIsolate.connect());
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
    await driftIsolate.shutdownAll();
  }, tags: 'background_isolate');

  test('errors propagate across isolates', () async {
    final isolate = await DriftIsolate.spawn(_backgroundConnection);
    final db = TodoDb.connect(await isolate.connect());

    try {
      await db.customStatement('UPDATE non_existing_table SET foo = bar');
      fail('Should have thrown an exception');
    } catch (e, s) {
      expect(e, isA<DriftRemoteException>());
      expect(e.toString(), contains('no such table: non_existing_table'));

      // The stack trace of remote exceptions should point towards the actual
      // source making the faulty call.
      expect(s.toString(), contains('main.<anonymous closure>'));
    }

    // Check that isolate is still usable
    await expectLater(
      db.customSelect('SELECT 1').get(),
      completion(isNotEmpty),
    );

    await db.close();
    await isolate.shutdownAll();
  }, tags: 'background_isolate');

  test('kills isolate when calling shutdownAll', () async {
    final spawned = ReceivePort();
    final done = ReceivePort();

    await Isolate.spawn(_createBackground, spawned.sendPort,
        onExit: done.sendPort);
    // The isolate shold eventually exit!
    expect(done.first, completion(anything));

    final drift = await spawned.first as DriftIsolate;
    await drift.shutdownAll();
  }, tags: 'background_isolate');

  test('shutting down will close the underlying executor', () async {
    final mockExecutor = MockExecutor();
    final isolate =
        DriftIsolate.inCurrent(() => DatabaseConnection(mockExecutor));
    await isolate.shutdownAll();

    verify(mockExecutor.close());
  });
}

void _runTests(FutureOr<DriftIsolate> Function() spawner, bool terminateIsolate,
    bool serialize) {
  late DriftIsolate isolate;
  late TodoDb database;

  setUp(() async {
    isolate = await spawner();

    database = TodoDb.connect(
      DatabaseConnection.delayed(isolate.connect()),
    );
  });

  tearDown(() async {
    await database.close();

    if (terminateIsolate) {
      await isolate.shutdownAll();
    }
  });

  test('can open database and send requests', () async {
    final result = await database.select(database.todosTable).get();
    expect(result, isEmpty);
  });

  test('can run beforeOpen', () async {
    var beforeOpenCalled = false;

    database.migration = MigrationStrategy(beforeOpen: (details) async {
      await database.customStatement('PRAGMA foreign_keys = ON');
      beforeOpenCalled = true;
    });

    // run a select statement to verify that the database is open
    await database.customSelect('SELECT 1').get();
    expect(beforeOpenCalled, isTrue);
  });

  test('stream queries work as expected', () async {
    final initialCompanion = TodosTableCompanion.insert(content: 'my content');

    final stream = database.select(database.todosTable).watchSingleOrNull();

    await expectLater(stream, emits(null));
    await database.into(database.todosTable).insert(initialCompanion);
    await expectLater(
      stream,
      emits(const TodoEntry(id: 1, content: 'my content')),
    );
  });

  test('can start transactions', () async {
    final initialCompanion = TodosTableCompanion.insert(content: 'my content');

    await database.transaction(() async {
      await database.into(database.todosTable).insert(initialCompanion);
    });

    final result = await database.select(database.todosTable).get();
    expect(result, isNotEmpty);
  });

  test('supports no-op transactions', () async {
    await database.transaction(() {
      return Future.value(null);
    });
  });

  test('supports transactions in migrations', () async {
    database.migration = MigrationStrategy(beforeOpen: (details) async {
      await database.transaction(() async {
        return await database.customSelect('SELECT 1').get();
      });
    });

    await database.customSelect('SELECT 2').get();
  });

  test('transactions have an isolated view on data', () async {
    // regression test for https://github.com/simolus3/drift/issues/324
    await database
        .customStatement('create table tbl (id integer primary key not null)');

    Future<void> expectRowCount(TodoDb db, int count) async {
      final rows = await db.customSelect('select * from tbl').get();
      expect(rows, hasLength(count));
    }

    final rowInserted = Completer<void>();
    final runTransaction = database.transaction(() async {
      await database.customInsert('insert into tbl default values');
      await expectRowCount(database, 1);
      rowInserted.complete();
      // Hold transaction open for expectRowCount() outside the transaction to
      // finish
      await Future.delayed(const Duration(seconds: 1));
      await database.customStatement('delete from tbl');
      await expectRowCount(database, 0);
    });

    await rowInserted.future;
    await expectRowCount(database, 0);
    await runTransaction; // wait for the transaction to complete
  });

  test("can't run queries on a closed database", () async {
    await database.customSelect('SELECT 1;').getSingle();

    await database.close();

    await expectLater(
        () => database.customSelect('SELECT 1;').getSingle(), throwsStateError);
  });

  test('can run deletes, updates and batches', () async {
    await database.into(database.users).insert(
        UsersCompanion.insert(name: 'simon.', profilePicture: Uint8List(0)));

    await database
        .update(database.users)
        .write(const UsersCompanion(name: Value('changed name')));
    var result = await database.select(database.users).getSingle();
    expect(result.name, 'changed name');

    await database.delete(database.users).go();

    await database.batch((batch) {
      batch.insert(
        database.users,
        UsersCompanion.insert(name: 'not simon', profilePicture: Uint8List(0)),
      );
    });

    result = await database.select(database.users).getSingle();
    expect(result.name, 'not simon');
  });

  test('transactions can be rolled back', () async {
    await expectLater(database.transaction(() async {
      await database.into(database.categories).insert(
          CategoriesCompanion.insert(description: 'my fancy description'));
      throw Exception('expected');
    }), throwsException);

    final result = await database.select(database.categories).get();
    expect(result, isEmpty);

    await database.close();
  });

  test('supports single quotes in text', () async {
    // Regression test for https://github.com/simolus3/drift/issues/1179
    await database.customStatement('CREATE TABLE sample(title TEXT)');
    await database.customStatement('INSERT INTO sample VALUES '
        "('O''Connor'), ('Tomeo''s');");

    final result =
        await database.customSelect('SELECT title FROM sample').get();
    expect(result.map((f) => f.read<String>('title')), ["O'Connor", "Tomeo's"]);
  });

  test('can dispatch table updates', () async {
    await database.customStatement('SELECT 1');
    expect(database.tableUpdates(TableUpdateQuery.onTable(database.users)),
        emitsInOrder([anything]));
    database.markTablesUpdated({database.users});
  });
}

DatabaseConnection _backgroundConnection() {
  return DatabaseConnection(NativeDatabase.memory());
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
  final DriftIsolate isolate;
  final SendPort sendDone;

  _BackgroundEntryMessage(this.isolate, this.sendDone);
}

void _createBackground(SendPort send) {
  final drift = DriftIsolate.inCurrent(
      () => DatabaseConnection(NativeDatabase.memory()),
      killIsolateWhenDone: true);
  send.send(drift);
}
