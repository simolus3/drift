import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../data/sample_data.dart' as people;
import '../database/database.dart';

import 'suite.dart';

void transactionTests(TestExecutor executor) {
  test('transactions write data', () async {
    final db = Database(executor.createConnection());

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    await db.transaction(() async {
      final florianId = await db.writeUser(people.florian);

      final dash = await db.getUserById(people.dashId);
      final florian = await db.getUserById(florianId);

      await db.makeFriends(dash, florian, goodFriends: true);
    });

    final countResult = await db.userCount().get();
    expect(countResult.single, 4);

    final friendsResult =
        await db.amountOfGoodFriends(people.dashId).getSingle();
    expect(friendsResult, 1);

    await executor.clearDatabaseAndClose(db);
  });

  test('transaction is rolled back then an exception occurs', () async {
    final db = Database(executor.createConnection());

    try {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      await db.transaction(() async {
        final florianId = await db.writeUser(people.florian);

        final dash = await db.getUserById(people.dashId);
        final florian = await db.getUserById(florianId);

        await db.makeFriends(dash, florian, goodFriends: true);
        throw Exception('nope i made a mistake please rollback thank you');
      });
    } on Exception catch (_) {}

    final countResult = await db.userCount().getSingle();
    expect(countResult, 3); // only the default folks

    final friendsResult =
        await db.amountOfGoodFriends(people.dashId).getSingle();
    expect(friendsResult, 0); // no friendship was inserted

    await executor.clearDatabaseAndClose(db);
  });

  test('can use no-op transactions', () async {
    final db = Database(executor.createConnection());
    await db.transaction(() => Future.value(null));
    await executor.clearDatabaseAndClose(db);
  });

  test(
    'nested transactions',
    () async {
      final db = Database(executor.createConnection());
      await db.users.delete().go();

      await db.transaction(() async {
        expect(await db.select(db.users).get(), isEmpty);

        await db.transaction(() async {
          await db.users.insertOne(UsersCompanion.insert(
              name: 'first user', birthDate: DateTime.now()));
          expect(await db.select(db.users).get(), hasLength(1));
        });

        expect(await db.select(db.users).get(), hasLength(1));

        final rollback = Exception('rollback');
        await expectLater(db.transaction(() async {
          await db.users.insertOne(UsersCompanion.insert(
              name: 'second user', birthDate: DateTime.now()));
          expect(await db.select(db.users).get(), hasLength(2));

          throw rollback;
        }), throwsA(rollback));

        expect(await db.select(db.users).get(), hasLength(1));
      });

      expect(await db.select(db.users).get(), hasLength(1));
      await executor.clearDatabaseAndClose(db);
    },
    skip: executor.supportsNestedTransactions
        ? false
        : 'Tested implementation does not support nested transactions',
  );
}
