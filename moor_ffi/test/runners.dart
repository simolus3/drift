import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:moor_ffi/database.dart';

import 'suite/select.dart' as select;
import 'suite/user_version.dart' as user_version;

var _tempFileCounter = 0;
List<File> _createdFiles = [];
File temporaryFile() {
  final count = _tempFileCounter++;
  final path =
      p.join(Directory.systemTemp.absolute.path, 'moor_ffi_test_$count.db');
  final file = File(path);
  _createdFiles.add(file);
  return file;
}

abstract class TestedDatabase {
  FutureOr<BaseDatabase> openFile(File file);
  FutureOr<BaseDatabase> openMemory();
}

class TestRegularDatabase implements TestedDatabase {
  @override
  BaseDatabase openFile(File file) => Database.openFile(file);

  @override
  BaseDatabase openMemory() => Database.memory();
}

class TestIsolateDatabase implements TestedDatabase {
  @override
  Future<BaseDatabase> openFile(File file) => IsolateDb.openFile(file);

  @override
  FutureOr<BaseDatabase> openMemory() => IsolateDb.openMemory();
}

void main() {
  group('regular database', () {
    _declareAll(TestRegularDatabase());
  });

  group('isolate database', () {
    _declareAll(TestIsolateDatabase());
  });

  tearDownAll(() async {
    for (var file in _createdFiles) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  });
}

void _declareAll(TestedDatabase db) {
  select.main(db);
  user_version.main(db);
}
