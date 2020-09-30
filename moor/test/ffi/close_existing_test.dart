@TestOn('vm')
import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('can close lost instances', () async {
    final file = File(p.join(Directory.systemTemp.path, 'moor_close.db'));
    if (file.existsSync()) file.deleteSync();

    // Create the first database holding the lock
    final db1 = VmDatabase(file);
    await db1.ensureOpen(_NullUser());
    await db1.runCustom('BEGIN EXCLUSIVE');

    // Close instances indirectly (we don't close db1)
    VmDatabase.closeExistingInstances();

    // Now open a second instance, it should be able to start a transactions
    final db2 = VmDatabase(file);
    await db2.ensureOpen(_NullUser());
    await db2.runCustom('BEGIN EXCLUSIVE');
    await db2.runCustom('COMMIT');

    await db2.close();
  });
}

class _NullUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
    return Future.value();
  }

  @override
  int get schemaVersion => 1;
}
