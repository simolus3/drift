@TestOn('vm')
import 'dart:async';
import 'dart:isolate';

import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:moor/ffi.dart';
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
  }, tags: 'background_isolate');

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
  }, tags: 'background_isolate');

  test('errors propagate across isolates', () async {
    final isolate = await MoorIsolate.spawn(_backgroundConnection);
    final db = TodoDb.connect(await isolate.connect());

    await expectLater(
      () => db.customStatement('UPDATE non_existing_table SET foo = bar'),
      throwsA(anything),
    );

    // Check that isolate is still usable
    await expectLater(
      db.customSelect('SELECT 1').get(),
      completion(isNotEmpty),
    );

    await db.close();
    await isolate.shutdownAll();
  }, tags: 'background_isolate');
}

void _runTests(
    FutureOr<MoorIsolate> Function() spawner, bool terminateIsolate) {
  late MoorIsolate isolate;
  late TodoDb database;

  setUp(() async {
    isolate = await spawner();

    database = TodoDb.connect(
      DatabaseConnection.delayed(isolate.connect(isolateDebugLog: false)),
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
    await expectLater(stream, emits(TodoEntry(id: 1, content: 'my content')));
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
    // regression test for https://github.com/simolus3/moor/issues/324
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
    // Regression test for https://github.com/simolus3/moor/issues/1179
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
        emitsInOrder([null]));
    database.markTablesUpdated({database.users});
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
