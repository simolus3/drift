import 'package:test/test.dart';

import '../ffi_test.dart';

void main(TestedDatabase db) {
  test('can set the user version on a database', () async {
    final file = temporaryFile();
    final opened = await db.openFile(file);

    var version = await opened.userVersion();
    expect(version, 0);

    await opened.setUserVersion(3);
    version = await opened.userVersion();
    expect(version, 3);

    // ensure that the version is stored on file
    await opened.close();

    final another = await db.openFile(file);
    expect(await another.userVersion(), 3);
    await another.close();
  });
}
