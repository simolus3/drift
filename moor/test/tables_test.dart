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
}
