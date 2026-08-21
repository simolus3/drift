import 'dart:async';

import 'package:async/async.dart';
import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils.dart';
import '../../test_utils/mocks.dart';

final _dataOfTodoEntry = {
  'id': 10,
  'title': 'A todo title',
  'content': 'Content',
  'target_date': null,
  'category': 3,
  'status': null,
};

const _todoEntry = TodoEntry(
  id: RowId(10),
  title: 'A todo title',
  content: 'Content',
  category: RowId(3),
);

void main() {
  late TodoDb db;
  late MockSession executor;

  setUp(() async {
    executor = MockSession();
    db = TodoDb(createConnection(executor));

    await db.initialize();
    clearInteractions(executor);
  });

  group('SELECT statements are generated', () {
    const usersColumns =
        '"id","name","is_awesome","profile_picture","creation_time"';

    test('for simple statements', () async {
      await db.select(db.users, distinct: true).get();
      verify(
        executor.executeSql('SELECT DISTINCT $usersColumns FROM "users";'),
      );
    });

    test('with limit statements', () async {
      await db.select(db.users).limit(10, offset: 0).get();
      verify(
        executor.executeSql(
          'SELECT $usersColumns FROM "users" LIMIT 10 OFFSET 0;',
        ),
      );
    });

    test('with simple limits', () async {
      await db.select(db.users).limit(10).get();

      verify(
        executor.executeSql('SELECT $usersColumns FROM "users" LIMIT 10;'),
      );
    });

    test('with like expressions', () async {
      await db.select(db.users).where((u) => u.name.like('Dash%')).get();
      verify(
        executor.executeSql(
          'SELECT $usersColumns FROM "users" WHERE "name" LIKE ?1;',
          ['Dash%'],
        ),
      );
    });

    test('with order-by clauses', () async {
      await (db.select(db.users)..orderBy([
            (u) => OrderingTerm.desc(u.isAwesome),
            (u) => OrderingTerm.asc(u.id),
          ]))
          .get();

      verify(
        executor.executeSql(
          'SELECT $usersColumns FROM "users" ORDER BY '
          '"is_awesome" DESC,"id" ASC;',
        ),
      );
    });

    test('with random order by clause', () async {
      await (db.select(
        db.users,
      )..orderBy([(u) => OrderingTerm.random()])).get();

      verify(
        executor.executeSql(
          'SELECT $usersColumns FROM "users" ORDER BY random() ASC;',
        ),
      );
    });

    test('with complex predicates', () async {
      await (db.select(db.users)..where(
            (u) => u.name.equals('Dash').not() & u.id.isGreaterThanValue(12),
          ))
          .get();

      verify(
        executor.executeSql(
          'SELECT $usersColumns FROM "users" WHERE NOT "name" = ?1 AND "id" > ?2;',
          ['Dash', 12],
        ),
      );
    });

    test('with expressions from boolean columns', () async {
      await (db.select(db.users)..where((u) => u.isAwesome)).get();

      verify(
        executor.executeSql(
          'SELECT $usersColumns FROM "users" WHERE "is_awesome";',
        ),
      );
    });

    test('with aliased tables', () async {
      final users = db.alias(db.users, 'u');
      await (db.select(
        users,
      )..where((u) => u.id.isLessThan(const Literal(5)))).get();

      verify(
        executor.executeSql(
          'SELECT $usersColumns FROM "users" AS "u" WHERE "id" < 5;',
        ),
      );
    });
  });

  group('SELECT results are parsed', () {
    test('when all fields are non-null', () {
      when(
        executor.execute(any),
      ).thenAnswer((_) async => queryResult([_dataOfTodoEntry]));

      expect(db.select(db.todosTable).get(), completion([_todoEntry]));
    });

    test('when some fields are null', () {
      final data = [
        {
          'id': 10,
          'title': null,
          'content': 'Content',
          'target_date': null,
          'category': null,
          'status': null,
        },
      ];
      const resolved = TodoEntry(
        id: RowId(10),
        title: null,
        content: 'Content',
        category: null,
      );

      when(executor.execute(any)).thenAnswer((_) async => queryResult(data));

      expect(db.select(db.todosTable).get(), completion([resolved]));
    });
  });

  group('queries for a single row', () {
    test('get once', () {
      when(
        executor.execute(any),
      ).thenAnswer((_) async => queryResult([_dataOfTodoEntry]));
      expect(db.select(db.todosTable).getSingle(), completion(_todoEntry));
    });

    test('get once without rows', () {
      when(executor.execute(any)).thenAnswer((_) async => queryResult([]));

      expect(db.select(db.todosTable).getSingle(), throwsA(anything));
      expect(db.select(db.todosTable).getSingleOrNull(), completion(isNull));
    });

    test('get multiple times', () async {
      final resultRows = <List<Map<String, dynamic>>>[
        [_dataOfTodoEntry],
        [],
        [_dataOfTodoEntry, _dataOfTodoEntry],
      ];
      var currentRow = 0;

      when(executor.execute(any)).thenAnswer((_) {
        return Future.value(queryResult(resultRows[currentRow++]));
      });

      expectLater(
        db.select(db.todosTable).watchSingle(),
        emitsInOrder([_todoEntry, emitsError(anything), emitsError(anything)]),
      );
      expectLater(
        db.select(db.todosTable).watchSingleOrNull(),
        emitsInOrder([_todoEntry, isNull, emitsError(anything)]),
      );

      await pumpEventQueue(); // First select as listeners attach
      db.markTablesUpdated({db.todosTable});
      await pumpEventQueue(); // Second select due to invalidation
      db.markTablesUpdated({db.todosTable});
      // Third select due to invalidation
    });
  });

  test('applies implicit type converter', () async {
    when(executor.execute(any)).thenAnswer((_) async {
      return queryResult([
        {
          'id': 1,
          'desc': 'description',
          'priority': 2,
          'description_in_upper_case': 'DESCRIPTION',
        },
      ]);
    });

    final category = await db.select(db.categories).getSingle();

    expect(
      category,
      const Category(
        id: RowId(1),
        description: 'description',
        descriptionInUpperCase: 'DESCRIPTION',
        priority: CategoryPriority.high,
      ),
    );
  });

  test('watching a view will update when a referenced table updates', () async {
    final stream = StreamQueue(db.select(db.categoryTodoCountView).watch());
    await expectLater(stream, emits(isEmpty));

    db.markTablesUpdated([db.categories]);
    await expectLater(stream, emits(isEmpty));
  });

  test('select from subquery', () async {
    await db.initialize();

    final data = [_dataOfTodoEntry];
    when(executor.execute(any)).thenAnswer((_) async => queryResult(data));

    final subquery = Subquery(db.select(db.todosTable), 's');
    final rows = await db.select(subquery).get();

    expect(rows, [_todoEntry]);

    verify(
      executor.executeSql(
        'SELECT "c0","c1","c2","c3","c4","c5" FROM (SELECT "id" AS "c0","title" AS "c1","content" AS "c2","target_date" AS "c3","category" AS "c4","status" AS "c5" FROM "todos") "s";',
      ),
    );
  });

  test('select from table-valued function', () async {
    final each = JsonExpression.parse(db.todosTable.content).jsonEach(r'$.foo');

    final query = db
        .select(db.todosTable)
        .innerJoin(each, on: each.atom.isNotNull(), includeInResult: false);

    await query.get();

    verify(
      executor.executeSql(
        'SELECT "todos"."id","todos"."title","todos"."content","todos"."target_date","todos"."category","todos"."status" FROM "todos" INNER JOIN json_each(jsonb("todos"."content"),?1) ON "json_each"."atom" IS NOT NULL;',
        [r'$.foo'],
      ),
    );
  });

  group('count', () {
    test('all', () async {
      when(executor.execute(any)).thenAnswer(
        (_) async => queryResult([
          {'c0': 3},
        ]),
      );

      final result = await db.count(db.todosTable).getSingle();
      expect(result, 3);

      verify(executor.executeSql('SELECT COUNT(*) FROM "todos";'));
    });

    test('with filter', () async {
      when(executor.execute(any)).thenAnswer(
        (_) async => queryResult([
          {'c0': 2},
        ]),
      );

      final result = await db
          .count(db.todosTable, where: (row) => row.id.isGreaterThanValue(12))
          .getSingle();
      expect(result, 2);

      verify(
        executor.executeSql('SELECT COUNT(*) FROM "todos" WHERE "id" > ?1;', [
          12,
        ]),
      );
    });
  });

  test('select expressions', () async {
    when(executor.execute(any)).thenAnswer(
      (_) async => queryResult([
        {'c0': true},
      ]),
    );

    final exists = existsQuery(db.select(db.todosTable));
    final result = await db.selectExpressions([exists]).getSingle();

    verify(executor.executeSql('SELECT EXISTS (SELECT 1 FROM "todos");'));
    expect(result.read(exists), isTrue);
  });
}
