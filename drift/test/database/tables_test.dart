import 'package:drift/drift.dart';
import 'package:drift/src/connections/result_set.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockSession executor;

  setUp(() {
    executor = MockSession();
    db = TodoDb(createConnection(executor));
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

  test('can convert a companion to a row class', () async {
    const companion = SharedTodosCompanion(
      todo: Value(3),
      user: Value(4),
    );

    final user = db.sharedTodos.mapFromCompanion(companion, db);
    expect(
      user,
      const SharedTodo(todo: 3, user: 4),
    );
  });

  test('can map from row without table prefix', () async {
    final rowData = {
      'id': 1,
      'title': 'some title',
      'content': 'do this',
      'target_date': null,
      'category': null,
    };

    final structure =
        ResultSetStructure().withSelectStarFromSingleTable(db.todosTable);

    final resultSet = DriftResultSet(
        structure,
        RawResultSet.generate(
            1, (_, rs) => RawRow.byMap(resultSet: rs, values: rowData)),
        db.dialect);

    final todo = resultSet.single.readTable(db.todosTable);
    expect(
      todo,
      const TodoEntry(
        id: RowId(1),
        title: 'some title',
        content: 'do this',
        targetDate: null,
        category: null,
      ),
    );
  });
  test('Table classes expose the name of the sql table', () {
    expect($TodosTableTable.$name, 'todos');
  });
}
