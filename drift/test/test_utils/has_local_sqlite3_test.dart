@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

import '../../tool/download_sqlite3.dart' as download;
import 'database_vm.dart';

void main() {
  preferLocalSqlite3();

  final path = expectedLocalSqlite3Path;
  final printWarning = path != null && !File(path).existsSync();

  test(
    'check for local sqlite3 library',
    () {
      var actual = sqlite3Version.versionNumber;
      // https://www.sqlite.org/c3ref/c_source_id.html
      var major = actual ~/ 1000000;
      var minor = (actual % 1000000) ~/ 1000;
      var patch = actual % 1000;

      var downloadCode = 100 * (patch + 100 * (minor + 100 * major));
      expect(
        downloadCode.toString(),
        download.latest.version,
        reason: "Your local sqlite3 build used to test drift doesn't match "
            'the expected version, possibly leading to failing tests. '
            'You have $downloadCode, drift expects ${download.latest}. '
            'Please run `dart run too/download_sqlite3.dart` to fix this.',
      );
    },
    skip: printWarning
        ? 'Local sqlite3 library for drift tests does not exist, falling back '
            'to the one from the OS. Please run `dart run tool/download_sqlite3.dart`'
        : null,
  );
}
