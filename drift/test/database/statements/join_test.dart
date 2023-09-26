import 'package:async/async.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

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
    final categoryTodoCountView = db.alias(db.categoryTodoCountView, 'ct');

    await db.select(todos).join([
      leftOuterJoin(categories, categories.id.equalsExp(todos.category)),
      leftOuterJoin(categoryTodoCountView,
          categoryTodoCountView.categoryId.equalsExp(categories.id)),
    ]).get();

    verify(executor.runSelect(
        'SELECT '
        '"t"."id" AS "t.id", '
        '"t"."title" AS "t.title", '
        '"t"."content" AS "t.content", '
        '"t"."target_date" AS "t.target_date", '
        '"t"."category" AS "t.category", '
        '"t"."status" AS "t.status", '
        '"c"."id" AS "c.id", '
        '"c"."desc" AS "c.desc", '
        '"c"."priority" AS "c.priority", '
        '"c"."description_in_upper_case" AS "c.description_in_upper_case", '
        '"ct"."category_id" AS "ct.category_id", '
        '"ct"."description" AS "ct.description", '
        '"ct"."item_count" AS "ct.item_count" '
        'FROM "todos" "t" '
        'LEFT OUTER JOIN "categories" "c" '
        'ON "c"."id" = "t"."category" '
        'LEFT OUTER JOIN "category_todo_count_view" "ct" '
        'ON "ct"."category_id" = "c"."id";',
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
          't.status': 'workInProgress',
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
          status: TodoStatus.workInProgress,
        ));

    expect(
      row.readTable(categories),
      const Category(
        id: 3,
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
        const TodoEntry(
          id: 5,
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
      ..where((t) => t.id.isSmallerThanValue(3))
      ..orderBy([(t) => OrderingTerm(expression: t.title)]);

    await normalQuery.join(
        [innerJoin(categories, categories.id.equalsExp(todos.category))]).get();

    verify(executor.runSelect(
        argThat(contains('WHERE "t"."id" < ? ORDER BY "t"."title" ASC')), [3]));
  });

  test('limit clause is kept', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    final normalQuery = db.select(todos)..limit(10, offset: 5);

    await normalQuery.join(
        [innerJoin(categories, categories.id.equalsExp(todos.category))]).get();

    verify(executor.runSelect(argThat(contains('LIMIT 10 OFFSET 5')), []));
  });

  test('can be watched', () async {
    final todos = db.alias(db.todosTable, 't');
    final categories = db.alias(db.categories, 'c');

    final query = db
        .select(todos)
        .join([innerJoin(categories, todos.category.equalsExp(categories.id))]);

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

    final query = (db.selectOnly(a)..where(c.todo.isNull())).join([
      leftOuterJoin(b, b.id.equalsExp(a.id)),
      leftOuterJoin(c, c.todo.equalsExp(b.id))
    ])
      ..addColumns([b.description])
      ..groupBy([b.description]);

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
        .join([innerJoin(categories, todos.category.equalsExp(categories.id))])
      ..where(todos.id.isSmallerThanValue(5))
      ..where(categories.id.isBiggerOrEqualValue(10));

    await query.get();

    verify(executor.runSelect(
        argThat(contains('WHERE "t"."id" < ? AND "c"."id" >= ?')), [5, 10]));
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
          'c0': 11
        }
      ];
    });

    final result = await query.getSingle();

    verify(executor.runSelect(
      'SELECT "c"."id" AS "c.id", "c"."desc" AS "c.desc", '
      '"c"."priority" AS "c.priority", "c"."description_in_upper_case" AS '
      '"c.description_in_upper_case", LENGTH("c"."desc") AS "c0" '
      'FROM "categories" "c";',
      [],
    ));

    expect(
      result.readTable(categories),
      equals(
        const Category(
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
          'c0': 11,
        },
      ];
    });

    final result = await query.getSingle();

    verify(executor.runSelect(
      'SELECT "c"."id" AS "c.id", "c"."desc" AS "c.desc", "c"."priority" AS "c.priority"'
      ', "c"."description_in_upper_case" AS "c.description_in_upper_case", '
      'LENGTH("c"."desc") AS "c0" '
      'FROM "categories" "c" '
      'INNER JOIN "todos" "t" ON "c"."id" = "t"."category";',
      [],
    ));

    expect(
      result.readTable(categories),
      equals(
        const Category(
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
          'c0': 10,
          'c.description_in_upper_case': 'DESC',
        }
      ];
    });

    final result = await query.getSingle();

    verify(executor.runSelect(
        'SELECT "c"."id" AS "c.id", "c"."desc" AS "c.desc", '
        '"c"."priority" AS "c.priority", '
        '"c"."description_in_upper_case" AS "c.description_in_upper_case", '
        'COUNT("t"."id") AS "c0" '
        'FROM "categories" "c" INNER JOIN "todos" "t" ON "t"."category" = "c"."id" '
        'GROUP BY "c"."id" HAVING COUNT("t"."id") >= ?;',
        [10]));

    expect(result.readTableOrNull(todos), isNull);
    expect(
      result.readTable(categories),
      const Category(
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
        'SELECT AVG(LENGTH("todos"."content")) AS "c0", '
        'MAX(LENGTH("todos"."content")) AS "c1" FROM "todos";',
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
        'SELECT "categories"."id" AS "categories.id", COUNT("todos"."id") AS "c1" '
        'FROM "categories" INNER JOIN "todos" ON "todos"."category" = "categories"."id" '
        'GROUP BY "categories"."id";',
        []));

    expect(result.read(categories.id), equals(2));
    expect(result.read(todos.id.count()), equals(10));
  });

  test('use selectOnly(includeJoinedTableColumns) instead of useColumns',
      () async {
    final categories = db.categories;
    final todos = db.todosTable;

    final query = db.selectOnly(categories).join([
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
        'SELECT "categories"."id" AS "categories.id", COUNT("todos"."id") AS "c1" '
        'FROM "categories" INNER JOIN "todos" ON "todos"."category" = "categories"."id" '
        'GROUP BY "categories"."id";',
        []));

    expect(result.read(categories.id), equals(2));
    expect(result.read(todos.id.count()), equals(10));
  });

  test('injects custom error message when a table is used multiple times',
      () async {
    when(executor.runSelect(any, any)).thenAnswer((_) => Future.error('nah'));

    expect(
      db.select(db.todosTable).join([crossJoin(db.todosTable)]).get(),
      throwsA(isA<DriftWrappedException>()
          .having((e) => e.toString(), 'toString', contains('possible cause'))),
    );

    // Joining with aliases should not throw
    final t1 = db.alias(db.todosTable, 't1');
    final t2 = db.alias(db.todosTable, 't2');

    expect(
      db.select(t1).join([crossJoin(t2)]).get(),
      throwsA(isNot(isA<DriftWrappedException>())),
    );
  });

  group('subquery', () {
    test('can be joined', () async {
      final subquery = Subquery(
        db.select(db.todosTable)
          ..orderBy([(row) => OrderingTerm.desc(row.title.length)])
          ..limit(10),
        's',
      );

      final query = db.selectOnly(db.categories)
        ..addColumns([db.categories.id])
        ..join([
          innerJoin(subquery,
              subquery.ref(db.todosTable.category).equalsExp(db.categories.id))
        ]);
      await query.get();

      verify(
        executor.runSelect(
          'SELECT "categories"."id" AS "categories.id" FROM "categories" '
          'INNER JOIN (SELECT * FROM "todos" '
          'ORDER BY LENGTH("todos"."title") DESC LIMIT 10) s '
          'ON "s"."category" = "categories"."id";',
          argThat(isEmpty),
        ),
      );
    });

    test('use column from subquery', () async {
      when(executor.runSelect(any, any)).thenAnswer((_) {
        return Future.value([
          {'c0': 42}
        ]);
      });

      final sumOfTitleLength = db.todosTable.title.length.sum();
      final subquery = Subquery(
          db.selectOnly(db.todosTable)
            ..addColumns([db.todosTable.category, sumOfTitleLength])
            ..groupBy([db.todosTable.category]),
          's');

      final readableLength = subquery.ref(sumOfTitleLength);
      final query = db.selectOnly(db.categories)
        ..addColumns([readableLength])
        ..join([
          innerJoin(subquery,
              subquery.ref(db.todosTable.category).equalsExp(db.categories.id))
        ]);

      final row = await query.getSingle();

      verify(
        executor.runSelect(
          'SELECT "s"."c1" AS "c0" FROM "categories" '
          'INNER JOIN ('
          'SELECT "todos"."category" AS "todos.category", '
          'SUM(LENGTH("todos"."title")) AS "c1" FROM "todos" '
          'GROUP BY "todos"."category") s '
          'ON "s"."todos.category" = "categories"."id";',
          argThat(isEmpty),
        ),
      );

      expect(row.read(readableLength), 42);
    });
  });
}
