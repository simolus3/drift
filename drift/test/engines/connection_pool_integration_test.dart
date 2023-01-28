@TestOn('vm')
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' show join;
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/database_vm.dart';

String fileName = 'drift-wal-integration-test.db';
final _file = File(join(Directory.systemTemp.path, fileName));

QueryExecutor _createExecutor() => NativeDatabase(_file);

DatabaseConnection _forBackgroundIsolate() {
  return DatabaseConnection(_createExecutor());
}

void main() {
  preferLocalSqlite3();

  setUp(() async {
    if (await _file.exists()) {
      await _file.delete();
    }
  });

  test('can use a multi-executor setup', () async {
    final isolate = await DriftIsolate.spawn(_forBackgroundIsolate);

    // create an executor that runs selects in this isolate and writes in
    // another isolate.
    final background = await isolate.connect();
    final foreground = background.withExecutor(MultiExecutor.withReadPool(
      reads: [_createExecutor()],
      write: background.executor,
    ));

    final db = TodoDb(foreground);

    await db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(description: 'description'));

    final result = await db.select(db.categories).getSingle();
    expect(result.description, 'description');

    await db.close();
    await isolate.shutdownAll();
  });

  tearDown(_file.delete);
}
