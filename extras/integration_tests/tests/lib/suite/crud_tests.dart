import 'package:test/test.dart';
import 'package:tests/database/database.dart';
import 'package:tests/suite/suite.dart';

void crudTests(TestExecutor executor) {
  test('inserting updates a select stream', () async {
    final db = Database(executor.createExecutor());
    final friends = db.watchFriendsOf(1).asBroadcastStream();

    final a = await db.getUserById(1);
    final b = await db.getUserById(2);

    expect(await friends.first, isEmpty);

    // after we called makeFriends(a,b)
    final expectation = expectLater(friends, emits(equals(<User>[b])));

    await db.makeFriends(a, b);
    await expectation;

    await db.close();
  });

  test('IN ? expressions can be expanded', () async {
    // regression test for https://github.com/simolus3/moor/issues/156
    final db = Database(executor.createExecutor());

    final result = await db.usersById([1, 2, 3]);

    expect(result.map((u) => u.name), ['Dash', 'Duke', 'Go Gopher']);

    await db.close();
  });

  test('runCustom with args', () async {
    // https://github.com/simolus3/moor/issues/406
    final db = Database(executor.createExecutor());

    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    await db.customStatement(
        'INSERT INTO friendships (first_user, second_user) VALUES (?, ?)',
        <int>[1, 2]);

    expect(await db.friendsOf(1), isNotEmpty);
  });
}
