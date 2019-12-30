import 'dart:io';

import 'package:moor_ffi/database.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('can set the user version on a database', () {
    final file = File(p.join(
        Directory.systemTemp.absolute.path, 'moor_ffi_test_user_version.db'));
    final opened = Database.openFile(file);

    var version = opened.userVersion();
    expect(version, 0);

    opened.setUserVersion(3);
    version = opened.userVersion();
    expect(version, 3);

    // ensure that the version is stored on file
    opened.close();

    final another = Database.openFile(file);
    expect(another.userVersion(), 3);
    another.close();

    file.deleteSync();
  });
}
