import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockExecutor executor;

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
    const companion = SharedTodosCompanion(
      todo: Value(3),
      user: Value(4),
    );

    final user = db.sharedTodos.mapFromCompanion(companion);
    expect(
      user,
      SharedTodo(todo: 3, user: 4),
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
