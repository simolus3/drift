import 'package:test/test.dart';

import '../tests.dart';

void crudTests(TestExecutor executor) {
  test('inserting updates a select stream', () async {
    final db = Database(executor.createConnection());
    final friends = db.friendsOf(1).watch().asBroadcastStream();

    final a = await db.getUserById(1);
    final b = await db.getUserById(2);

    expect(await friends.first, isEmpty);

    await db.makeFriends(a, b);
    await expectLater(friends, emits(equals(<User>[b])));

    await executor.clearDatabaseAndClose(db);
  });

  test('update row', () async {
    final db = Database(executor.createConnection());

    await (db.update(db.users)..where((tbl) => tbl.id.equals(1)))
        .write(UsersCompanion(name: Value("Jack")));
    final updatedUser = await db.getUserById(1);

    expect(updatedUser.name, equals('Jack'));
    await executor.clearDatabaseAndClose(db);
  });

  test('insert duplicate', () async {
    final db = Database(executor.createConnection());

    await expectLater(
        db.into(db.users).insert(marcell),
        throwsA(toString(
            matches(RegExp(r'unique constraint', caseSensitive: false)))));
    await executor.clearDatabaseAndClose(db);
  });

  test('insert on conflict update', () async {
    final db = Database(executor.createConnection());

    await db.into(db.users).insertOnConflictUpdate(marcell);
    final updatedUser = await db.getUserById(1);

    expect(updatedUser.name, equals('Marcell'));
    await executor.clearDatabaseAndClose(db);
  });

  test('insert mode', () async {
    final db = Database(executor.createConnection());
    if (db.executor.dialect == SqlDialect.postgres) {
      await expectLater(
          db.into(db.users).insert(marcell, mode: InsertMode.insertOrReplace),
          throwsA(isA<ArgumentError>()));
    }
    await executor.clearDatabaseAndClose(db);
  });

  test('supports RETURNING', () async {
    final db = Database(executor.createConnection());
    final result = await db.returning(1, 2, true);

    expect(result,
        [Friendship(firstUser: 1, secondUser: 2, reallyGoodFriends: true)]);
    await executor.clearDatabaseAndClose(db);
  },
      skip: executor.supportsReturning
          ? null
          : 'Runner does not support RETURNING');

  test('IN ? expressions can be expanded', () async {
    // regression test for https://github.com/simolus3/drift/issues/156
    final db = Database(executor.createConnection());
    final result = await db.usersById([1, 2, 3]).get();

    expect(result.map((u) => u.name), ['Dash', 'Duke', 'Go Gopher']);
    await executor.clearDatabaseAndClose(db);
  });

  test('nested results', () async {
    final db = Database(executor.createConnection());

    final a = await db.getUserById(1);
    final b = await db.getUserById(2);

    await db.makeFriends(a, b, goodFriends: true);
    final result = await db.friendshipsOf(a.id).getSingle();

    expect(result, FriendshipsOfResult(reallyGoodFriends: true, user: b));
    await executor.clearDatabaseAndClose(db);
  });

  test('runCustom with args', () async {
    // https://github.com/simolus3/drift/issues/406
    final db = Database(executor.createConnection());

    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    if (db.executor.dialect == SqlDialect.postgres) {
      await db.customStatement(
          'INSERT INTO friendships (first_user, second_user) VALUES (@1, @2)',
          <int>[1, 2]);
    } else {
      await db.customStatement(
          'INSERT INTO friendships (first_user, second_user) VALUES (?1, ?2)',
          <int>[1, 2]);
    }

    expect(await db.friendsOf(1).get(), isNotEmpty);
    await executor.clearDatabaseAndClose(db);
  });
}
