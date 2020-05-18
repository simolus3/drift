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
      // false for https://github.com/simolus3/moor/issues/559
      isAwesome: Value(false),
    );

    final user = db.users.mapFromCompanion(companion);
    expect(
      user,
      User(
        id: 3,
        name: 'hi',
        profilePicture: null,
        isAwesome: false,
        creationTime: null,
      ),
    );
  });

  test('can map from row without table prefix', () {
    final rowData = {
      'id': 1,
      'title': 'some title',
      'content': 'do this',
      'target_date': null,
      'category': null,
    };
    final todo = db.todosTable.mapFromRowOrNull(QueryRow(rowData, db));
    expect(
      todo,
      TodoEntry(
        id: 1,
        title: 'some title',
        content: 'do this',
        targetDate: null,
        category: null,
      ),
    );
  });
}
