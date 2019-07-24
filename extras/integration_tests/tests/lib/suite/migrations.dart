import 'package:test/test.dart';
import 'package:tests/database/database.dart';

import 'suite.dart';

void migrationTests(TestExecutor executor) {
  test('creates users table when opening version 1', () async {
    final database = Database(executor.createExecutor(), schemaVersion: 1);

    // we write 3 users when the database is created
    final count = await database.userCount();
    expect(count.single.cOUNTid, 3);
  });
}
