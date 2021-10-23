import 'package:test/test.dart';
import 'package:tests/data/sample_data.dart';
import 'package:tests/database/database.dart';
import 'package:tests/suite/suite.dart';

import '../tests.dart';

void crudTests(TestExecutor executor) {
  test('inserting updates a select stream', () async {
    final db = Database(executor.createConnection());
    final friends = db.friendsOf(1).watch().asBroadcastStream();

    final a = await db.getUserById(1);
    final b = await db.getUserById(2);

    expect(await friends.first, isEmpty);

    // after we called makeFriends(a,b)
    final expectation = expectLater(friends, emits(equals(<User>[b])));

    await db.makeFriends(a, b);
    await expectation;

    await db.close();
  });

  test('update row', () async {
    final db = Database(executor.createConnection());

    await db.update(db.users)
      ..where((tbl) => tbl.id.equals(1))
      ..write(UsersCompanion(name: Value("Jack")));

    final updatedUser = await db.getUserById(1);
    expect(updatedUser.name, equals('Jack'));

    await db.close();
  });

  test('insert duplicate', () async {
    final db = Database(executor.createConnection());

    await expectLater(
        db.into(db.users).insert(marcell),
        throwsA(toString(
            matches(RegExp(r'unique constraint', caseSensitive: false)))));

    await db.close();
  });

  test('insert on conflict update', () async {
    final db = Database(executor.createConnection());

    await db.into(db.users).insertOnConflictUpdate(marcell);

    final updatedUser = await db.getUserById(1);
    expect(updatedUser.name, equals('Marcell'));

    await db.close();
  });

  test('insert mode', () async {
    final db = Database(executor.createConnection());
    if (db.executor.dialect == SqlDialect.postgres) {
      await expectLater(
          db.into(db.users).insert(marcell, mode: InsertMode.insertOrReplace),
          throwsA(isA<ArgumentError>()));
    }
  });

  test('supports RETURNING', () async {
    final db = Database(executor.createConnection());
    final result = await db.returning(1, 2, true);
    expect(result,
        [Friendship(firstUser: 1, secondUser: 2, reallyGoodFriends: true)]);

    await db.close();
  },
      skip: executor.supportsReturning
          ? null
          : 'Runner does not support RETURNING');

  test('IN ? expressions can be expanded', () async {
    // regression test for https://github.com/simolus3/moor/issues/156
    final db = Database(executor.createConnection());

    final result = await db.usersById([1, 2, 3]).get();

    expect(result.map((u) => u.name), ['Dash', 'Duke', 'Go Gopher']);

    await db.close();
  });

  test('nested results', () async {
    final db = Database(executor.createConnection());

    final a = await db.getUserById(1);
    final b = await db.getUserById(2);

    await db.makeFriends(a, b, goodFriends: true);
    final result = await db.friendshipsOf(a.id).getSingle();

    expect(result, FriendshipsOfResult(reallyGoodFriends: true, user: b));
    await db.close();
  });

  test('runCustom with args', () async {
    // https://github.com/simolus3/moor/issues/406
    final db = Database(executor.createConnection());

    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    await db.customStatement(
        'INSERT INTO friendships (first_user, second_user) VALUES (?1, ?2)',
        <int>[1, 2]);

    expect(await db.friendsOf(1).get(), isNotEmpty);
    await db.close();
  });
}
