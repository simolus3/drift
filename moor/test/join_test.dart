import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/join.dart';
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

  test('generates join statements', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    await db.select(todos).join([
      leftOuterJoin(categories, categories.id.equalsExp(todos.category))
    ]).get();

    verify(executor.runSelect(
        'SELECT t.id AS "t.id", t.title AS "t.title", t.content AS "t.content", '
        't.target_date AS "t.target_date", '
        't.category AS "t.category", c.id AS "c.id", c.`desc` AS "c.desc" '
        'FROM todos t LEFT OUTER JOIN categories c ON c.id = t.category;',
        argThat(isEmpty)));
  });

  test('parses results from multiple tables', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    final date = DateTime(2019, 03, 20);
    when(executor.runSelect(any, any)).thenAnswer((_) {
      return Future.value([
        {
          't.id': 5,
          't.title': 'title',
          't.content': 'content',
          't.target_date': date.millisecondsSinceEpoch ~/ 1000,
          't.category': 3,
          'c.id': 3,
          'c.desc': 'description',
        }
      ]);
    });

    final result = await db.select(todos, distinct: true).join([
      leftOuterJoin(categories, categories.id.equalsExp(todos.category))
    ]).get();

    expect(result, hasLength(1));

    final row = result.single;
    expect(
        row.readTable(todos),
        TodoEntry(
          id: 5,
          title: 'title',
          content: 'content',
          targetDate: date,
          category: 3,
        ));

    expect(
        row.readTable(categories), Category(id: 3, description: 'description'));

    verify(executor.runSelect(argThat(contains('DISTINCT')), any));
  });

  test('reports null when no data is available', () async {
    when(executor.runSelect(any, any)).thenAnswer((_) {
      return Future.value([
        {
          'todos.id': 5,
          'todos.title': 'title',
          'todos.content': 'content',
          'todos.target_date': null,
          'todos.category': null,
        }
      ]);
    });

    final result = await db.select(db.todosTable).join([
      leftOuterJoin(
          db.categories, db.categories.id.equalsExp(db.todosTable.category))
    ]).get();

    expect(result, hasLength(1));

    final row = result.single;
    expect(row.readTable(db.categories), null);
    expect(
        row.readTable(db.todosTable),
        TodoEntry(
          id: 5,
          title: 'title',
          content: 'content',
        ));
  });

  test('where and order-by clauses are kept', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    final normalQuery = db.select(todos)
      ..where((t) => t.id.isSmallerThanValue(3))
      ..orderBy([(t) => OrderingTerm(expression: t.title)]);

    await normalQuery.join(
        [innerJoin(categories, categories.id.equalsExp(todos.category))]).get();

    verify(executor.runSelect(
        argThat(contains('WHERE t.id < ? ORDER BY t.title ASC')), [3]));
  });

  test('injects custom error message when a table is used multiple times',
      () async {
    when(executor.runSelect(any, any)).thenAnswer((_) => Future.error('nah'));

    MoorWrappedException wrappedException;
    try {
      await db.select(db.todosTable).join([crossJoin(db.todosTable)]).get();
      fail('expected this to throw');
    } on MoorWrappedException catch (e) {
      wrappedException = e;
    }

    expect(wrappedException.toString(), contains('possible cause'));
  });
}
