@TestOn('browser')
import 'dart:html';

import 'package:moor/moor_web.dart';
import 'package:test/test.dart';
import 'package:tests/tests.dart';

class WebExecutor extends TestExecutor {
  final String name = 'db';

  @override
  bool get supportsReturning => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.fromExecutor(WebDatabase(name));
  }

  @override
  Future deleteData() {
    window.localStorage.clear();
    return Future.value();
  }
}

class WebExecutorIndexedDb extends TestExecutor {
  @override
  bool get supportsReturning => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.fromExecutor(
      WebDatabase.withStorage(MoorWebStorage.indexedDb('foo')),
    );
  }

  @override
  Future deleteData() async {
    await window.indexedDB.deleteDatabase('moor_databases');
  }
}

void main() {
  group('using local storage', () {
    runAllTests(WebExecutor());
  });

  group('using IndexedDb', () {
    runAllTests(WebExecutorIndexedDb());
  });
}
