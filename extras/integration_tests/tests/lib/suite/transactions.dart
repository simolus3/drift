import 'package:test/test.dart';
import 'package:tests/data/sample_data.dart';
import 'package:tests/database/database.dart';

import 'suite.dart';

void transactionTests(TestExecutor executor) {
  test('transactions write data', () async {
    final db = Database(executor.createExecutor());

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    await db.transaction((_) async {
      final florianId = await db.writeUser(People.florian);

      final dash = await db.getUserById(People.dashId);
      final florian = await db.getUserById(florianId);

      await db.makeFriends(dash, florian, goodFriends: true);
    });

    final countResult = await db.userCount();
    expect(countResult.single.cOUNTid, 4);

    final friendsResult = await db.amountOfGoodFriends(People.dashId);
    expect(friendsResult.single.count, 1);

    await db.close();
  });

  test('transaction is rolled back then an exception occurs', () async {
    final db = Database(executor.createExecutor());

    try {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      await db.transaction((_) async {
        final florianId = await db.writeUser(People.florian);

        final dash = await db.getUserById(People.dashId);
        final florian = await db.getUserById(florianId);

        await db.makeFriends(dash, florian, goodFriends: true);
        throw Exception('nope i made a mistake please rollback thank you');
      });
      fail('the transaction should have thrown!');
    } on Exception catch (_) {}

    final countResult = await db.userCount();
    expect(countResult.single.cOUNTid, 3); // only the default folks

    final friendsResult = await db.amountOfGoodFriends(People.dashId);
    expect(friendsResult.single.count, 0); // no friendship was inserted

    await db.close();
  });
}
