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
    isolate.kill();
  });

  test('can open database and send requests', () async {
    final database = TodoDb.connect(isolateConnection);

    final result = await database.select(database.todosTable).get();
    expect(result, isEmpty);
  });
}

DatabaseConnection _backgroundConnection() {
  return DatabaseConnection.fromExecutor(VmDatabase.memory());
}
