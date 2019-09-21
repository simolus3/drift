import 'package:test/test.dart';
import 'package:tests/database/database.dart';
import 'package:tests/suite/suite.dart';

void crudTests(TestExecutor executor) {
  test('inserting updates a select stream', () async {
    final db = Database(executor.createExecutor());
    final friends = db.watchFriendsOf(1);

    final a = await db.getUserById(1);
    final b = await db.getUserById(2);

    final expectation = expectLater(
      friends,
      emitsInOrder(
        [
          isEmpty, // initial state without friendships
          [b] // after we called makeFriends(a,b)
        ],
      ),
    );

    await db.makeFriends(a, b);
    await expectation;
  });

  test('IN ? expressions can be expanded', () async {
    // regression test for https://github.com/simolus3/moor/issues/156
    final db = Database(executor.createExecutor());

    final result = await db.usersById([1, 2, 3]);

    expect(result.map((u) => u.name), ['Dash', 'Duke', 'Go Gopher']);
  });
}
