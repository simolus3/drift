import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:tests/database/database.dart';

final File mainFile =
    File(join(Directory.systemTemp.path, 'moor-save-and-restore-tests-1'));
final File createdForSwap =
    File(join(Directory.systemTemp.path, 'moor-save-and-restore-tests-2'));

void main() {
  test('can save and restore a database', () async {
    if (await mainFile.exists()) {
      await mainFile.delete();
    }
    if (await createdForSwap.exists()) {
      await createdForSwap.delete();
    }

    const nameInSwap = 'swap user';
    const nameInMain = 'main';

    // Prepare the file we're swapping in later
    final dbForSetup = Database.executor(VmDatabase(createdForSwap));
    await dbForSetup.into(dbForSetup.users).insert(
        UsersCompanion.insert(name: nameInSwap, birthDate: DateTime.now()));
    await dbForSetup.close();

    // Open the main file
    var db = Database.executor(VmDatabase(mainFile));
    await db.into(db.users).insert(
        UsersCompanion.insert(name: nameInMain, birthDate: DateTime.now()));
    await db.close();

    // Copy swap file to main file
    await mainFile.writeAsBytes(await createdForSwap.readAsBytes(),
        flush: true);

    // Re-open database
    db = Database.executor(VmDatabase(mainFile));
    final users = await db.select(db.users).get();

    expect(
      users.map((u) => u.name),
      allOf(contains(nameInSwap), isNot(contains(nameInMain))),
    );
  });
}
