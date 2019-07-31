import 'package:moor/moor.dart';
import 'package:test/test.dart';
import 'package:tests/suite/transactions.dart';

import 'custom_objects.dart';
import 'migrations.dart';

abstract class TestExecutor {
  QueryExecutor createExecutor();

  /// Delete the data that would be written by the executor.
  Future deleteData();
}

void runAllTests(TestExecutor executor) {
  tearDown(() async {
    await executor.deleteData();
  });

  migrationTests(executor);
  customObjectTests(executor);
  transactionTests(executor);
}
