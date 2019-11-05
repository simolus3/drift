import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';

void main() {
  MoorIsolate isolate;
  DatabaseConnection isolateConnection;

  setUp(() async {
    isolate = await MoorIsolate.spawn(_backgroundConnection);
    isolateConnection = await isolate.connect(isolateDebugLog: false);
  });

  tearDown(() {
    isolateConnection.executor.close();
    return isolate.shutdownAll();
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
