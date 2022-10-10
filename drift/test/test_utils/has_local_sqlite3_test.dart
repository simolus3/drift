import 'dart:io';

import 'package:test/test.dart';

import 'database_vm.dart';

void main() {
  final path = expectedLocalSqlite3Path;
  final printWarning = path != null && !File(path).existsSync();

  test(
    'check for local sqlite3 library',
    () {},
    skip: printWarning
        ? 'Local sqlite3 library for drift tests does not exist, falling back '
            'to the one from the OS. Please run `dart run tool/download_sqlite3.dart`'
        : null,
  );
}
