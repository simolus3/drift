import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockSession executor;

  setUp(() async {
    executor = MockSession();
    db = TodoDb(createConnection(executor));

    await db.initialize();
    clearInteractions(executor);
  });

  test('generates join statements', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');
    final categoryTodoCountView = db.alias(db.categoryTodoCountView, 'ct');

    await db
        .select(todos)
        .leftOuter(categories, on: categories.id.equalsExp(todos.category))
        .leftOuter(categoryTodoCountView,
            on: categoryTodoCountView.categoryId.equalsExp(categories.id))
        .get();

    verify(executor.executeSql(
      'SELECT '
      '"t"."id" AS "c0",'
      '"t"."title" AS "c1",'
      '"t"."content" AS "c2",'
      '"t"."target_date" AS "c3",'
      '"t"."category" AS "c4",'
      '"t"."status" AS "c5",'
      '"c"."id" AS "c6",'
      '"c"."desc" AS "c7",'
      '"c"."priority" AS "c8",'
      '"c"."description_in_upper_case" AS "c9",'
      '"ct"."category_id" AS "c10",'
      '"ct"."description" AS "c11",'
      '"ct"."item_count" AS "c12" '
      'FROM "todos" AS "t" '
      'LEFT OUTER JOIN "categories" AS "c" '
      'ON "c"."id" = "t"."category" '
      'LEFT OUTER JOIN "category_todo_count_view" AS "ct" '
      'ON "ct"."category_id" = "c"."id";',
    ));
  });

  test('parses results from multiple tables', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    final date = DateTime.utc(2019, 03, 20);
    when(executor.execute(any)).thenAnswer((_) async {
      return queryResult([
        {
          'c0': 5,
          'c1': 'title',
          'c2': 'content',
          'c3': date.toIso8601String(),
          'c4': 3,
          'c5': 'workInProgress',
          'c6': 3,
          'c7': 'description',
          'c8': 2,
          'c9': 'DESCRIPTION',
        }
      ]);
    });

    final result = await db
        .select(todos, distinct: true)
        .leftOuter(categories, on: categories.id.equalsExp(todos.category))
        .get();

    expect(result, hasLength(1));

    final row = result.single;
    expect(
        row.readTable(todos),
        TodoEntry(
          id: RowId(5),
          title: 'title',
          content: 'content',
          targetDate: date,
          category: RowId(3),
          status: TodoStatus.workInProgress,
        ));

    expect(
      row.readTable(categories),
      const Category(
        id: RowId(3),
        description: 'description',
        priority: CategoryPriority.high,
        descriptionInUpperCase: 'DESCRIPTION',
      ),
    );

    // Also make sure we can read individual columns
    expect(row.read(todos.id), 5);
    expect(row.read(categories.description), 'description');

    expect(row.read(todos.status), 'workInProgress');
    expect(row.readWithConverter(todos.status), TodoStatus.workInProgress);

    verify(executor.executeSql(contains('DISTINCT'), anything));
  });

  test('throws when no data is available', () async {
    when(executor.execute(any)).thenAnswer((_) {
      return Future.value(queryResult([
        {
          'c0': 5,
          'c1': 'title',
          'c2': 'content',
        }
      ]));
    });

    final result = await db
        .select(db.todosTable)
        .leftOuter(db.categories,
            on: db.categories.id.equalsExp(db.todosTable.category))
        .get();

    expect(result, hasLength(1));

    final row = result.single;
    expect(() => row.readTable(db.categories), throwsArgumentError);
    expect(
        row.readTable(db.todosTable),
        const TodoEntry(
          id: RowId(5),
          title: 'title',
          content: 'content',
        ));

    expect(row.readTableOrNull(db.categories), isNull);
    expect(row.read(db.categories.id), isNull);
    expect(row.readWithConverter(db.categories.priority), isNull);
  });

  test('where and order-by clauses are kept', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    final normalQuery = db.select(todos)
      ..where((t) => t.id.isLessThanValue(3))
      ..orderBy([(t) => OrderingTerm(expression: t.title)]);

    await normalQuery
        .innerJoin(categories, on: categories.id.equalsExp(todos.category))
        .get();

    verify(executor.executeSql(
        contains('WHERE "t"."id" < ?1 ORDER BY "t"."title" ASC'), [3]));
  });

  test('limit clause is kept', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    final normalQuery = db.select(todos)..limit(10, offset: 5);

    await normalQuery
        .innerJoin(categories, on: categories.id.equalsExp(todos.category))
        .get();

    verify(executor.executeSql(contains('LIMIT 10 OFFSET 5')));
  });

  test('can be watched', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    final query = db
        .select(todos)
        .innerJoin(categories, on: todos.category.equalsExp(categories.id));

    final queue = StreamQueue(query.watch());
    expect(await queue.next, isEmpty);

    db.markTablesUpdated({todos});
    db.markTablesUpdated({categories});
    expect(await queue.next, isEmpty);
  });

  test('updates when any queried table changes in transaction', () {
    // Nonsense query, repro for https://github.com/simolus3/drift/issues/910
    final a = db.users;
    final b = db.categories;
    final c = db.sharedTodos;

    final query = db
        .selectOnly(a)
        .where(c.todo.isNull())
        .leftOuter(b, on: b.id.equalsExp(a.id))
        .leftOuter(c, on: c.todo.equalsExp(b.id))
        .addColumn(b.description)
        .groupBy([b.description]);

    final stream = query.watch();
    expectLater(stream, emitsInOrder([<Object?>[], <Object?>[]]));

    return db.transaction(() async {
      db.markTablesUpdated({b});
    });
  });

  test('setting where multiple times forms conjunction', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    final query = db
        .select(todos)
        .innerJoin(categories, on: todos.category.equalsExp(categories.id))
        .where(todos.id.isLessThanValue(5))
        .where(categories.id.isGreaterOrEqualValue(10));

    await query.get();

    verify(executor.executeSql(
        contains('WHERE "t"."id" < ?1 AND "c"."id" >= ?2'), [5, 10]));
  });

  test('supports custom columns and results', () async {
    final categories = db.alias(db.categories, 'c');
    final descriptionLength = categories.description.length;

    final query = db.select(categories).addColumns([descriptionLength]);

    when(executor.execute(any)).thenAnswer((_) async {
      return queryResult([
        {'c0': 3, 'c1': 'Description', 'c2': 1, 'c3': 'DESCRIPTION', 'c4': 11}
      ]);
    });

    final result = await query.getSingle();

    verify(executor.executeSql(
      'SELECT "id" AS "c0",'
      '"desc" AS "c1",'
      '"priority" AS "c2",'
      '"description_in_upper_case" AS "c3",'
      'LENGTH("desc") AS "c4"'
      ' FROM "categories" AS "c";',
    ));

    expect(
      result.readTable(categories),
      equals(
        const Category(
          id: RowId(3),
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

    final query = db.select(categories).addColumn(descriptionLength).innerJoin(
          todos,
          on: categories.id.equalsExp(todos.category),
          includeInResult: false,
        );

    when(executor.execute(any)).thenAnswer((_) async {
      return queryResult([
        {
          'c0': 3,
          'c1': 'Description',
          'c2': 1,
          'c3': 'DESCRIPTION',
          'c4': 11,
        },
      ]);
    });

    final result = await query.getSingle();

    verify(executor.executeSql(
      'SELECT "c"."id" AS "c0","c"."desc" AS "c1","c"."priority" AS "c2",'
      '"c"."description_in_upper_case" AS "c3",'
      'LENGTH("c"."desc") AS "c4" '
      'FROM "categories" AS "c" '
      'INNER JOIN "todos" AS "t" ON "c"."id" = "t"."category";',
      [],
    ));

    expect(
      result.readTable(categories),
      equals(
        const Category(
          id: RowId(3),
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

    final query = db
        .select(categories)
        .innerJoin(
          todos,
          on: todos.category.equalsExp(categories.id),
          includeInResult: false,
        )
        .addColumns([amountOfTodos]).groupBy(
      [categories.id],
      having: amountOfTodos.isGreaterOrEqualValue(10),
    );

    when(executor.execute(any)).thenAnswer((_) async {
      return queryResult([
        {
          'c0': 3,
          'c1': 'desc',
          'c2': 0,
          'c3': 'DESC',
          'c4': 10,
        }
      ]);
    });

    final result = await query.getSingle();

    verify(executor.executeSql(
      'SELECT "c"."id" AS "c0","c"."desc" AS "c1",'
      '"c"."priority" AS "c2","c"."description_in_upper_case" AS "c3",'
      'COUNT("t"."id") AS "c4" '
      'FROM "categories" AS "c" '
      'INNER JOIN "todos" AS "t" ON "t"."category" = "c"."id" '
      'GROUP BY "c"."id" HAVING COUNT("t"."id") >= ?1;',
      [10],
    ));

    expect(() => result.readTableOrNull(todos), throwsA(anything));
    expect(
      result.readTable(categories),
      const Category(
        id: RowId(3),
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

    when(executor.execute(any)).thenAnswer((_) async {
      return queryResult([
        {'c0': 3.0, 'c1': null},
      ]);
    });

    final row = await query.getSingle();

    verify(executor.executeSql(
        'SELECT AVG(LENGTH("content")) AS "c0",'
        'MAX(LENGTH("content")) AS "c1" FROM "todos";',
        []));

    expect(row.read(avgLength), 3.0);
    expect(row.read(maxLength), isNull);
    expect(() => row.read(minLength), throwsArgumentError);
  });

  test('join on JoinedSelectStatement', () async {
    final categories = db.categories;
    final todos = db.todosTable;

    final query = db
        .selectOnly(categories)
        .innerJoin(todos,
            on: todos.category.equalsExp(categories.id), includeInResult: false)
        .addColumns([categories.id, todos.id.count()]).groupBy([categories.id]);

    when(executor.execute(any)).thenAnswer((_) async {
      return queryResult([
        {
          'c0': 2,
          'c1': 10,
        }
      ]);
    });

    final result = await query.getSingle();

    verify(executor.executeSql(
      'SELECT "categories"."id" AS "c0",COUNT("todos"."id") AS "c1" '
      'FROM "categories" INNER JOIN "todos" ON "todos"."category" = "categories"."id" '
      'GROUP BY "categories"."id";',
    ));

    expect(result.read(categories.id), equals(2));
    expect(result.read(todos.id.count()), equals(10));
  });

  test('use selectOnly(includeJoinedTableColumns) instead of useColumns',
      () async {
    final categories = db.categories;
    final todos = db.todosTable;

    final query = db
        .selectOnly(categories)
        .innerJoin(todos, on: todos.category.equalsExp(categories.id))
        .addColumns([categories.id, todos.id.count()]).groupBy([categories.id]);

    when(executor.execute(any)).thenAnswer((_) async {
      return queryResult([
        {
          'c0': 2,
          'c1': 10,
        }
      ]);
    });

    final result = await query.getSingle();

    verify(executor.executeSql(
        'SELECT "categories"."id" AS "c0",COUNT("todos"."id") AS "c1" '
        'FROM "categories" INNER JOIN "todos" ON "todos"."category" = "categories"."id" '
        'GROUP BY "categories"."id";',
        []));

    expect(result.read(categories.id), equals(2));
    expect(result.read(todos.id.count()), equals(10));
  });

  test('error when adding same table multiple times', () async {
    expect(
      () => db.select(db.todosTable).cross(db.todosTable),
      throwsA(isA<StateError>()),
    );

    // Joining with aliases should not throw
    final t1 = db.alias(db.todosTable, 't1');
    final t2 = db.alias(db.todosTable, 't2');

    expect(
      db.select(t1).cross(t2).get(),
      completes,
    );
  });

  test('right outer join', () {
    final stmt = db.select(db.todosTable).join([
      rightOuterJoin(
          db.categories, db.todosTable.category.equalsExp(db.categories.id))
    ]);

    expect(stmt, generates(contains('RIGHT OUTER JOIN')));
  });

  test('full outer join', () {
    final stmt = db.select(db.todosTable).join([
      fullOuterJoin(
          db.categories, db.todosTable.category.equalsExp(db.categories.id))
    ]);

    expect(stmt, generates(contains('FULL OUTER JOIN')));
  });

  group('subquery', () {
    test('can be joined', () async {
      final subquery = Subquery(
        db.select(db.todosTable)
          ..orderBy([(row) => OrderingTerm.desc(row.title.length)])
          ..limit(10),
        's',
      );

      await db
          .selectOnly(db.categories)
          .addColumns([db.categories.id])
          .innerJoin(subquery,
              on: subquery
                  .ref(db.todosTable.category)
                  .equalsExp(db.categories.id))
          .get();

      verify(executor.executeSql(
        'SELECT "categories"."id" AS "c0" FROM "categories" '
        'INNER JOIN (SELECT "todos"."id" AS "id","todos"."title" AS "title","todos"."content" AS "content","todos"."target_date" AS "target_date","todos"."category" AS "category","todos"."status" AS "status" FROM "todos" '
        'ORDER BY LENGTH("todos"."title") DESC LIMIT 10) "s" '
        'ON "s"."category" = "categories"."id";',
      ));
    });

    test('use column from subquery', () async {
      when(executor.execute(any)).thenAnswer((_) {
        return Future.value(queryResult([
          {'c0': 42}
        ]));
      });

      final sumOfTitleLength = db.todosTable.title.length.sum();
      final subquery = Subquery(
          db.selectOnly(db.todosTable)
            ..addColumns([db.todosTable.category, sumOfTitleLength])
            ..groupBy([db.todosTable.category]),
          's');

      final readableLength = subquery.ref(sumOfTitleLength);
      final query = db
          .selectOnly(db.categories)
          .addColumns([readableLength]).innerJoin(subquery,
              on: subquery
                  .ref(db.todosTable.category)
                  .equalsExp(db.categories.id));

      final row = await query.getSingle();

      verify(executor.executeSql(
        'SELECT "s"."c1" AS "c0" FROM "categories" '
        'INNER JOIN ('
        'SELECT "todos"."category" AS "c0",'
        'SUM(LENGTH("todos"."title")) AS "c1" FROM "todos" '
        'GROUP BY "todos"."category") "s" '
        'ON "s"."c0" = "categories"."id";',
      ));

      expect(row.read(readableLength), 42);
    });
  });

  group('compound operators', () {
    const expression = Literal<int>(42);

    test('are forbidden with an limit on the part', () {
      final a = db.selectOnly(db.users)..addColumns([expression]);
      final b = db.selectOnly(db.users)..limit(10);

      expect(() => a.union(b), throwsArgumentError);
    });

    test('are forbidden with an order-by on the part', () {
      final a = db.selectOnly(db.users)..addColumns([expression]);
      final b = db.selectOnly(db.users)
        ..addColumns([expression])
        ..orderBy([OrderingTerm.asc(db.users.id)]);

      expect(() => a.union(b), throwsArgumentError);
    });

    test('are forbidden with an compounds on the part', () {
      final a = db.selectOnly(db.users)..addColumns([expression]);
      final b = db.selectOnly(db.users)
        ..addColumns([expression])
        ..intersect(db.selectOnly(db.users)..addColumns([expression]));

      expect(() => a.union(b), throwsArgumentError);
    });

    test('are forbidden with different column counts', () {
      final a = db.selectOnly(db.users)..addColumns([expression]);
      final b = db.selectOnly(db.users);

      expect(() => a.union(b), throwsArgumentError);
    });

    group('generate correct statements', () {
      final operators = <(
        String,
        SelectStatement Function(BaseSelectStatement, BaseSelectStatement)
      )>[
        ('UNION', (a, b) => a.union(b)),
        ('UNION ALL', (a, b) => a.unionAll(b)),
        ('EXCEPT', (a, b) => a.except(b)),
        ('INTERSECT', (a, b) => a.intersect(b)),
      ];

      for (final (operator, method) in operators) {
        test('with $operator', () async {
          var a = db.selectOnly(db.users).addColumns([expression]).limit(10);
          final b = db.selectExpressions([const Literal<int>(84)]);

          when(executor.execute(any)).thenAnswer((_) {
            return Future.value(queryResult([
              {'c0': 42},
              {'c0': 84}
            ]));
          });

          a = method(a, b);

          final rows = await a.get();
          expect(rows.map((e) => e.read(expression)), [42, 84]);

          verify(
            executor.executeSql(
                'SELECT 42 AS "c0" FROM "users" $operator SELECT 84 AS "c0" LIMIT 10;'),
          );
        });
      }
    });
  });
}
