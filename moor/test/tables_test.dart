import 'package:moor/moor.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;

  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  test('aliased tables implement equals correctly', () {
    final first = db.users;
    final aliasA = db.alias(db.users, 'a');
    final anotherA = db.alias(db.categories, 'a');

    expect(first == aliasA, isFalse);
    // ignore: unrelated_type_equality_checks
    expect(anotherA == aliasA, isFalse);
    expect(aliasA == db.alias(db.users, 'a'), isTrue);
  });

  test('aliased table implement hashCode correctly', () {
    final first = db.users;
    final aliasA = db.alias(db.users, 'a');
    final anotherA = db.alias(db.categories, 'a');

    expect(first.hashCode == aliasA.hashCode, isFalse);
    expect(anotherA.hashCode == aliasA.hashCode, isFalse);
    expect(aliasA.hashCode == db.alias(db.users, 'a').hashCode, isTrue);
  });

  test('can convert a companion to a row class', () {
    const companion = UsersCompanion(
      id: Value(3),
      name: Value('hi'),
      profilePicture: Value.absent(),
      isAwesome: Value(true),
    );

    final user = db.users.mapFromCompanion(companion);
    expect(
      user,
      User(
        id: 3,
        name: 'hi',
        profilePicture: null,
        isAwesome: true,
        creationTime: null,
      ),
    );
  });
}
