@TestOn('vm')
import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';

import 'package:test/test.dart';

import 'package:path/path.dart' show join;

import '../data/tables/todos.dart';

String fileName = 'moor-wal-integration-test.db';
final _file = File(join(Directory.systemTemp.path, fileName));

QueryExecutor _createExecutor() => VmDatabase(_file);

DatabaseConnection _forBackgroundIsolate() {
  return DatabaseConnection.fromExecutor(_createExecutor());
}

void main() {
  setUp(() async {
    if (await _file.exists()) {
      await _file.delete();
    }
  });

  test('can use a multi-executor setup', () async {
    final isolate = await MoorIsolate.spawn(_forBackgroundIsolate);

    // create an executor that runs selects in this isolate and writes in
    // another isolate.
    final background = await isolate.connect();
    final foreground = background.withExecutor(MultiExecutor(
      read: _createExecutor(),
      write: background.executor,
    ));

    final db = TodoDb.connect(foreground);

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
