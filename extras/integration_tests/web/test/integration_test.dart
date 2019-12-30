@TestOn('browser')
import 'dart:html';

import 'package:tests/tests.dart';
import 'package:test/test.dart';
import 'package:moor/moor_web.dart';

class WebExecutor extends TestExecutor {
  final String name = 'db';

  @override
  QueryExecutor createExecutor() {
    return WebDatabase(name);
  }

  @override
  Future deleteData() {
    window.localStorage.clear();
    return Future.value();
  }
}

void main() {
  runAllTests(WebExecutor());
}
