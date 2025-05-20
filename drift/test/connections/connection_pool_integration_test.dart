@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/connections/isolate.dart';
import 'package:drift/connections/sqlite/native.dart';
import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:drift/src/connections/connection_pool.dart';
import 'package:path/path.dart' show join;
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/database_vm.dart';

String fileName = 'drift-wal-integration-test.db';
final _file = File(join(Directory.systemTemp.path, fileName));

Future<DriftSession> _createExecutor() async {
  return NativeDatabase.blockingImplementation(_file);
}

void main() {
  preferLocalSqlite3();

  setUp(() async {
    if (await _file.exists()) {
      await _file.delete();
    }
  });

  test('can use a multi-executor setup', () async {
    final isolate = await DriftIsolate.spawn(_createExecutor);

    // create an executor that runs selects in this isolate and writes in
    // another isolate.
    final background = await isolate.connect();
    final foreground = DriftSessionPool(
      write: background.$1,
      reads: [await _createExecutor()],
    );

    final db = TodoDb(DriftConnection.withImplementation(
      dialect: const SqliteDialect(),
      implementation: () async => (foreground, background.$2),
    ));

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
