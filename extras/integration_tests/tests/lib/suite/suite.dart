import 'package:moor/moor.dart';
import 'package:test/test.dart';
import 'package:tests/suite/crud_tests.dart';
import 'package:tests/suite/transactions.dart';

import 'custom_objects.dart';
import 'migrations.dart';

abstract class TestExecutor {
  DatabaseConnection createConnection();

  bool get supportsReturning => false;

  /// Delete the data that would be written by the executor.
  Future deleteData();
}

void runAllTests(TestExecutor executor) {
  moorRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  tearDown(() async {
    await executor.deleteData();
  });

  crudTests(executor);
  //migrationTests(executor);
  //customObjectTests(executor);
  //transactionTests(executor);

  test('can close database without interacting with it', () async {
    final connection = executor.createConnection();

    await connection.executor.close();
  });
}

Matcher toString(Matcher matcher) => _ToString(matcher);

class _ToString extends CustomMatcher {
  _ToString(Matcher matcher)
      : super("Object string represent is", "toString()", matcher);

  @override
  Object? featureValueOf(dynamic actual) => actual.toString();
}
