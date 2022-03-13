import 'package:drift/drift.dart' hide isNull;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  late TodoDb db;
  late MockExecutor executor;

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
        'SELECT t.id AS "t.id", t.title AS "t.title", '
        't.content AS "t.content", t.target_date AS "t.target_date", '
        't.category AS "t.category", c.id AS "c.id", c."desc" AS "c.desc", '
        'c.priority AS "c.priority", '
        'c.description_in_upper_case AS "c.description_in_upper_case" '
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
          'c.description_in_upper_case': 'DESCRIPTION',
          'c.priority': 2,
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
      row.readTable(categories),
      Category(
        id: 3,
        description: 'description',
        priority: CategoryPriority.high,
        descriptionInUpperCase: 'DESCRIPTION',
      ),
    );

    verify(executor.runSelect(argThat(contains('DISTINCT')), any));
  });

  test('throws when no data is available', () async {
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
    expect(() => row.readTable(db.categories), throwsArgumentError);
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

  test('limit clause is kept', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    final normalQuery = db.select(todos)..limit(10, offset: 5);

    await normalQuery.join(
        [innerJoin(categories, categories.id.equalsExp(todos.category))]).get();

    verify(executor.runSelect(argThat(contains('LIMIT 10 OFFSET 5')), []));
  });

  test('can be watched', () {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    final query = db
        .select(todos)
        .join([innerJoin(categories, todos.category.equalsExp(categories.id))]);

    final stream = query.watch();
    expectLater(stream, emitsInOrder([[], []]));

    db.markTablesUpdated({todos});
    db.markTablesUpdated({categories});
  });

  test('updates when any queried table changes in transaction', () {
    // Nonsense query, repro for https://github.com/simolus3/drift/issues/910
    final a = db.users;
    final b = db.categories;
    final c = db.sharedTodos;

    final query = (db.selectOnly(a)..where(c.todo.isNull())).join([
      leftOuterJoin(b, b.id.equalsExp(a.id)),
      leftOuterJoin(c, c.todo.equalsExp(b.id))
    ])
      ..addColumns([b.description])
      ..groupBy([b.description]);

    final stream = query.watch();
    expectLater(stream, emitsInOrder([[], []]));

    return db.transaction(() async {
      db.markTablesUpdated({b});
    });
  });

  test('setting where multiple times forms conjunction', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    final query = db
        .select(todos)
        .join([innerJoin(categories, todos.category.equalsExp(categories.id))])
      ..where(todos.id.isSmallerThanValue(5))
      ..where(categories.id.isBiggerOrEqualValue(10));

    await query.get();

    verify(executor
        .runSelect(argThat(contains('WHERE t.id < ? AND c.id >= ?')), [5, 10]));
  });

  test('supports custom columns and results', () async {
    final categories = db.alias(db.categories, 'c');
    final descriptionLength = categories.description.length;

    final query = db.select(categories).addColumns([descriptionLength]);

    when(executor.runSelect(any, any)).thenAnswer((_) async {
      return [
        {
          'c.id': 3,
          'c.desc': 'Description',
          'c.description_in_upper_case': 'DESCRIPTION',
          'c.priority': 1,
          'c4': 11
        }
      ];
    });

    final result = await query.getSingle();

    verify(executor.runSelect(
      'SELECT c.id AS "c.id", c."desc" AS "c.desc", '
      'c.priority AS "c.priority", c.description_in_upper_case AS '
      '"c.description_in_upper_case", LENGTH(c."desc") AS "c4" '
      'FROM categories c;',
      [],
    ));

    expect(
      result.readTable(categories),
      equals(
        Category(
          id: 3,
          description: 'Description',
          descriptionInUpperCase: 'DESCRIPTION',
          priority: CategoryPriority.medium,
        ),
      ),
    );
    expect(result.read(descriptionLength), 11);
  });

  test('supports custom columns + join', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');
    final descriptionLength = categories.description.length;

    final query = db.select(categories).addColumns([descriptionLength]).join([
      innerJoin(
        todos,
        categories.id.equalsExp(todos.category),
        useColumns: false,
      )
    ]);

    when(executor.runSelect(any, any)).thenAnswer((_) async {
      return [
        {
          'c.id': 3,
          'c.desc': 'Description',
          'c.description_in_upper_case': 'DESCRIPTION',
          'c.priority': 1,
          'c4': 11,
        },
      ];
    });

    final result = await query.getSingle();

    verify(executor.runSelect(
      'SELECT c.id AS "c.id", c."desc" AS "c.desc", c.priority AS "c.priority"'
      ', c.description_in_upper_case AS "c.description_in_upper_case", '
      'LENGTH(c."desc") AS "c4" '
      'FROM categories c '
      'INNER JOIN todos t ON c.id = t.category;',
      [],
    ));

    expect(
      result.readTable(categories),
      equals(
        Category(
          id: 3,
          description: 'Description',
          descriptionInUpperCase: 'DESCRIPTION',
          priority: CategoryPriority.medium,
        ),
      ),
    );
    expect(result.read(descriptionLength), 11);
  });

  test('group by', () async {
    final categories = db.alias(db.categories, 'c');
    final todos = db.alias(db.todosTable, 't');
    final amountOfTodos = todos.id.count();

    final query = db.select(categories).join([
      innerJoin(
        todos,
        todos.category.equalsExp(categories.id),
        useColumns: false,
      )
    ]);
    query
      ..addColumns([amountOfTodos])
      ..groupBy(
        [categories.id],
        having: amountOfTodos.isBiggerOrEqualValue(10),
      );

    when(executor.runSelect(any, any)).thenAnswer((_) async {
      return [
        {
          'c.id': 3,
          'c.desc': 'desc',
          'c.priority': 0,
          'c4': 10,
          'c.description_in_upper_case': 'DESC',
        }
      ];
    });

    final result = await query.getSingle();

    verify(executor.runSelect(
        'SELECT c.id AS "c.id", c."desc" AS "c.desc", '
        'c.priority AS "c.priority", '
        'c.description_in_upper_case AS "c.description_in_upper_case", '
        'COUNT(t.id) AS "c4" '
        'FROM categories c INNER JOIN todos t ON t.category = c.id '
        'GROUP BY c.id HAVING COUNT(t.id) >= ?;',
        [10]));

    expect(result.readTableOrNull(todos), isNull);
    expect(
      result.readTable(categories),
      Category(
        id: 3,
        description: 'desc',
        descriptionInUpperCase: 'DESC',
        priority: CategoryPriority.low,
      ),
    );
    expect(result.read(amountOfTodos), 10);
  });

  test('selectWithoutResults', () async {
    final avgLength = db.todosTable.content.length.avg();
    final maxLength = db.todosTable.content.length.max();
    final minLength = db.todosTable.content.length.min();
    final query = db.selectOnly(db.todosTable)
      ..addColumns([avgLength, maxLength]);

    when(executor.runSelect(any, any)).thenAnswer((_) async {
      return [
        {'c0': 3.0, 'c1': null},
      ];
    });

    final row = await query.getSingle();

    verify(executor.runSelect(
        'SELECT AVG(LENGTH(todos.content)) AS "c0", '
        'MAX(LENGTH(todos.content)) AS "c1" FROM todos;',
        []));

    expect(row.read(avgLength), 3.0);
    expect(row.read(maxLength), isNull);
    expect(() => row.read(minLength), throwsArgumentError);
  });

  test('join on JoinedSelectStatement', () async {
    final categories = db.categories;
    final todos = db.todosTable;

    final query = db.selectOnly(categories).join([
      innerJoin(
        todos,
        todos.category.equalsExp(categories.id),
        useColumns: false,
      )
    ]);
    query
      ..addColumns([categories.id, todos.id.count()])
      ..groupBy([categories.id]);

    when(executor.runSelect(any, any)).thenAnswer((_) async {
      return [
        {
          'categories.id': 2,
          'c1': 10,
        }
      ];
    });

    final result = await query.getSingle();

    verify(executor.runSelect(
        'SELECT categories.id AS "categories.id", COUNT(todos.id) AS "c1" '
        'FROM categories INNER JOIN todos ON todos.category = categories.id '
        'GROUP BY categories.id;',
        []));

    expect(result.read(categories.id), equals(2));
    expect(result.read(todos.id.count()), equals(10));
  });

  test('use selectOnly(includeJoinedTableColumns) instead of useColumns',
      () async {
    final categories = db.categories;
    final todos = db.todosTable;

    final query =
        db.selectOnly(categories, includeJoinedTableColumns: false).join([
      innerJoin(
        todos,
        todos.category.equalsExp(categories.id),
      )
    ]);
    query
      ..addColumns([categories.id, todos.id.count()])
      ..groupBy([categories.id]);

    when(executor.runSelect(any, any)).thenAnswer((_) async {
      return [
        {
          'categories.id': 2,
          'c1': 10,
        }
      ];
    });

    final result = await query.getSingle();

    verify(executor.runSelect(
        'SELECT categories.id AS "categories.id", COUNT(todos.id) AS "c1" '
        'FROM categories INNER JOIN todos ON todos.category = categories.id '
        'GROUP BY categories.id;',
        []));

    expect(result.read(categories.id), equals(2));
    expect(result.read(todos.id.count()), equals(10));
  });

  test('injects custom error message when a table is used multiple times',
      () async {
    when(executor.runSelect(any, any)).thenAnswer((_) => Future.error('nah'));

    DriftWrappedException wrappedException;
    try {
      await db.select(db.todosTable).join([crossJoin(db.todosTable)]).get();
      fail('expected this to throw');
    } on DriftWrappedException catch (e) {
      wrappedException = e;
    }

    expect(wrappedException.toString(), contains('possible cause'));
  });
}
