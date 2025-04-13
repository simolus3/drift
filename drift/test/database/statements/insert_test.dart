import 'dart:typed_data';

import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockSession executor;
  late MockStreamQueries streamQueries;

  setUp(() async {
    executor = MockSession();
    streamQueries = MockStreamQueries();

    final connection = createConnection(executor, streams: streamQueries);
    db = TodoDb(connection);

    // Run migrations and clear interactions to make verifying generated
    // statements easier.
    await db.initialize();
    clearInteractions(executor);
  });

  test('generates insert statements', () async {
    await db.into(db.todosTable).insert(const TodosTableCompanion(
          content: Value('Implement insert statements'),
          title: Value.absent(),
        ));

    verify(executor.executeSql('INSERT INTO "todos" ("content") VALUES (?1)',
        ['Implement insert statements']));
  });

  test('can insert floating point values', () async {
    // regression test for https://github.com/simolus3/drift/issues/30
    await db.into(db.tableWithoutPK).insert(
        CustomRowClass.map(42, 3.1415, custom: MyCustomObject('custom'))
            .toInsertable());

    verify(executor.executeSql(
        'INSERT INTO "table_without_p_k" '
        '("not_really_an_id","some_float","web_safe_int","custom") '
        'VALUES (?1,?2,?3,?4)',
        [42, 3.1415, isNull, anything]));
  });

  test('can insert BigInt values', () async {
    await db.into(db.tableWithoutPK).insert(CustomRowClass.map(42, 0,
            webSafeInt: BigInt.one, custom: MyCustomObject('custom'))
        .toInsertable());

    verify(executor.executeSql(
        'INSERT INTO "table_without_p_k" '
        '("not_really_an_id","some_float","web_safe_int","custom") '
        'VALUES (?1,?2,?3,?4)',
        [42, 0.0, BigInt.one, anything]));
  });

  test('generates insert or replace statements', () async {
    await db
        .into(db.todosTable)
        .mode(InsertMode.insertOrReplace)
        .insert(const TodoEntry(
          id: RowId(113),
          content: 'Done',
        ));

    verify(executor.executeSql(
        'INSERT OR REPLACE INTO "todos" ("id","content") VALUES (?1,?2)',
        [113, 'Done']));
  });

  test('generates DEFAULT VALUES statement when otherwise empty', () async {
    await db.into(db.pureDefaults).insert(const PureDefaultsCompanion());

    verify(
        executor.executeSql('INSERT INTO "pure_defaults" DEFAULT VALUES', []));
  });

  test('notifies stream queries on inserts', () async {
    when(executor.execute(any)).thenAnswer((_) async {
      return queryResult(null, lastInsertRowId: 3, affectedRows: 1);
    });

    await db.into(db.users).insert(UsersCompanion(
          name: const Value('User McUserface'),
          isAwesome: const Value(true),
          profilePicture: Value(Uint8List(0)),
        ));

    verify(streamQueries.handleTableUpdates(
        {const TableUpdate('users', kind: UpdateKind.insert)}));
  });

  test('notifies stream queries on insertReturning', () async {
    when(executor.execute(any)).thenAnswer((_) async {
      return queryResult(affectedRows: 1, lastInsertRowId: 5, [
        {
          'id': 5,
          'name': 'User McUserface',
          'is_awesome': true,
          'profile_picture': Uint8List(0),
          'creation_time': DateTime.now().toIso8601String(),
        }
      ]);
    });

    final user = await db.into(db.users).insertReturning(UsersCompanion(
          name: const Value('User McUserface'),
          isAwesome: const Value(true),
          profilePicture: Value(Uint8List(0)),
        ));

    verify(streamQueries.handleTableUpdates(
        {const TableUpdate('users', kind: UpdateKind.insert)}));

    expect(user.id, 5);
  });

  test('can provide null value for column with additional checks', () async {
    await db.into(db.todosTable).insert(
        TodosTableCompanion.insert(content: 'content', title: Value(null)));

    verify(executor.executeSql(
        'INSERT INTO "todos" ("title","content") VALUES (?1,?2)',
        [null, 'content']));
  });

  test('reports auto-increment id', () {
    when(executor.execute(any)).thenAnswer(
        (_) => Future.value(queryResult(null, lastInsertRowId: 42)));

    expect(
      db
          .into(db.todosTable)
          .insert(const TodosTableCompanion(content: Value('Bottom text'))),
      completion(42),
    );
  });

  test('evaluates client-default functions', () async {
    await db.into(db.tableWithoutPK).insert(
        TableWithoutPKCompanion.insert(notReallyAnId: 3, someFloat: 3.14));

    // the client default generates a uuid
    final uuidRegex = RegExp(
        r'[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12}');

    verify(executor.executeSql(
      'INSERT INTO "table_without_p_k" ("not_really_an_id","some_float","custom") '
      'VALUES (?1,?2,?3)',
      [3, 3.14, matches(uuidRegex)],
    ));
  });

  test('escaped when column name is keyword', () async {
    await db.into(db.pureDefaults).insert(
        PureDefaultsCompanion.insert(txt: Value(MyCustomObject('foo'))));

    verify(executor.executeSql(
        'INSERT INTO "pure_defaults" ("insert") VALUES (?1)', ['foo']));
  });

  test('can insert custom companions', () async {
    await db.into(db.users).insert(UsersCompanion.custom(
        isAwesome: const Literal(true),
        name: const Variable('User name'),
        profilePicture: Expression.customComponent(CustomComponent('_custom_')),
        creationTime: currentDateAndTime));

    verify(
      executor.executeSql(
        'INSERT INTO "users" ("creation_time","name","is_awesome","profile_picture") '
        'VALUES (CURRENT_TIMESTAMP,?1,1,_custom_)',
        ['User name'],
      ),
    );
  });

  test('can use an upsert clause', () async {
    await db.into(db.todosTable).insert(
      TodosTableCompanion.insert(content: 'my content'),
      onConflict: DoUpdate((old) {
        return TodosTableCompanion.custom(
            content: const Variable('important: ') + old.content);
      }),
    );

    verify(executor.executeSql(
      'INSERT INTO "todos" ("content") VALUES (?1) '
      'ON CONFLICT("id") DO UPDATE SET "content" = ?2 || "content"',
      ['my content', 'important: '],
    ));
  });

  test('can use an upsert clause with where', () async {
    await db.into(db.todosTable).insert(
          TodosTableCompanion.insert(content: 'my content'),
          onConflict: DoUpdate((old) {
            return TodosTableCompanion.custom(
                content: const Variable('important: ') + old.content);
          }, where: (old) => old.category.equals(1)),
        );

    verify(executor.executeSql(
      'INSERT INTO "todos" ("content") VALUES (?1) '
      'ON CONFLICT("id") DO UPDATE SET "content" = ?2 || "content" '
      'WHERE "category" = ?3',
      ['my content', 'important: ', 1],
    ));
  });

  test('can apply selective index in upsert clause', () async {
    await db.into(db.todosTable).insert(
          TodosTableCompanion.insert(content: 'my content'),
          onConflict: DoUpdate((old) {
            return TodosTableCompanion.custom(
                content: const Variable('important: ') + old.content);
          }, targetCondition: (old) => old.category.equals(1)),
        );

    verify(executor.executeSql(
      'INSERT INTO "todos" ("content") VALUES (?1) '
      'ON CONFLICT("id") WHERE "category" = ?2 '
      'DO UPDATE SET "content" = ?3 || "content"',
      ['my content', 1, 'important: '],
    ));
  });

  test('can ignore conflict target', () async {
    await db.into(db.todosTable).insert(
          TodosTableCompanion.insert(content: 'my content'),
          onConflict: DoUpdate((old) {
            return TodosTableCompanion.custom(
                content: const Variable('important: ') + old.content);
          }, target: []),
        );

    verify(executor.executeSql(
      'INSERT INTO "todos" ("content") VALUES (?1) '
      'ON CONFLICT DO UPDATE SET "content" = ?2 || "content"',
      ['my content', 'important: '],
    ));
  });

  test(
    'can use multiple upsert targets',
    () async {
      await db
          .into(db.todosTable)
          .insert(TodosTableCompanion.insert(content: 'my content'),
              onConflict: UpsertMultiple([
                DoUpdate(
                  (old) {
                    return TodosTableCompanion.custom(
                        content: const Variable('important: ') + old.content);
                  },
                ),
                DoUpdate(
                  (old) {
                    return TodosTableCompanion.custom(
                        content: const Variable('second: ') + old.content);
                  },
                  target: [db.todosTable.content],
                ),
              ]));

      verify(executor.executeSql(
        'INSERT INTO "todos" ("content") VALUES (?1) '
        'ON CONFLICT("id") DO UPDATE SET "content" = ?2 || "content" '
        'ON CONFLICT("content") DO UPDATE SET "content" = ?3 || "content"',
        ['my content', 'important: ', 'second: '],
      ));
    },
  );

  test(
    'can mix `DoNothing` and `DoUpdate` in `UpsertMultiple`',
    () async {
      await db
          .into(db.todosTable)
          .insert(TodosTableCompanion.insert(content: 'my content'),
              onConflict: UpsertMultiple([
                DoUpdate(
                  (old) {
                    return TodosTableCompanion.custom(
                        content: const Variable('important: ') + old.content);
                  },
                ),
                DoNothing(
                  target: [db.todosTable.content],
                ),
              ]));

      verify(executor.executeSql(
        'INSERT INTO "todos" ("content") VALUES (?1) '
        'ON CONFLICT("id") DO UPDATE SET "content" = ?2 || "content" '
        'ON CONFLICT("content") DO NOTHING',
        ['my content', 'important: '],
      ));
    },
  );

  test(
    'can nest `UpsertMultiple`',
    () async {
      await db
          .into(db.todosTable)
          .insert(TodosTableCompanion.insert(content: 'my content'),
              onConflict: UpsertMultiple([
                DoUpdate(
                  (old) {
                    return TodosTableCompanion.custom(
                        content: const Variable('important: ') + old.content);
                  },
                ),
                UpsertMultiple(
                  [
                    DoNothing(
                      target: [db.todosTable.content],
                    ),
                  ],
                ),
              ]));

      verify(executor.executeSql(
        'INSERT INTO "todos" ("content") VALUES (?1) '
        'ON CONFLICT("id") DO UPDATE SET "content" = ?2 || "content" '
        'ON CONFLICT("content") DO NOTHING',
        ['my content', 'important: '],
      ));
    },
  );

  test(
    'can use multiple upsert targets with where',
    () async {
      await db
          .into(db.todosTable)
          .insert(TodosTableCompanion.insert(content: 'my content'),
              onConflict: UpsertMultiple([
                DoUpdate((old) {
                  return TodosTableCompanion.custom(
                      content: const Variable('important: ') + old.content);
                }, where: (old) => old.category.equals(1)),
                DoUpdate((old) {
                  return TodosTableCompanion.custom(
                      content: const Variable('second: ') + old.content);
                },
                    target: [db.todosTable.content],
                    where: (old) => old.category.equals(1)),
              ]));

      verify(executor.executeSql(
        'INSERT INTO "todos" ("content") VALUES (?1) '
        'ON CONFLICT("id") DO UPDATE SET "content" = ?2 || "content" '
        'WHERE "category" = ?3 '
        'ON CONFLICT("content") DO UPDATE SET "content" = ?4 || "content" '
        'WHERE "category" = ?3',
        ['my content', 'important: ', 1, 'second: '],
      ));
    },
  );

  test('can use a custom conflict clause', () async {
    await db.into(db.todosTable).insert(
          TodosTableCompanion.insert(content: 'my content'),
          onConflict: DoUpdate(
            (old) => TodosTableCompanion.insert(content: 'changed'),
            target: [db.todosTable.content],
          ),
        );

    verify(executor.executeSql(
      'INSERT INTO "todos" ("content") VALUES (?1) '
      'ON CONFLICT("content") DO UPDATE SET "content" = ?2',
      ['my content', 'changed'],
    ));
  });

  test('can use a custom conflict clause with where', () async {
    await db.into(db.todosTable).insert(
          TodosTableCompanion.insert(content: 'my content'),
          onConflict: DoUpdate(
              (old) => TodosTableCompanion.insert(content: 'changed'),
              target: [db.todosTable.content],
              where: (old) => old.content.equalsExp(old.title)),
        );

    verify(executor.executeSql(
      'INSERT INTO "todos" ("content") VALUES (?1) '
      'ON CONFLICT("content") DO UPDATE SET "content" = ?2 '
      'WHERE "content" = "title"',
      ['my content', 'changed'],
    ));
  });

  test('can use do nothing on upsert', () async {
    await db.into(db.todosTable).insert(
          TodosTableCompanion.insert(content: 'my content'),
          onConflict: DoNothing(),
        );

    verify(executor.executeSql(
      'INSERT INTO "todos" ("content") VALUES (?1) '
      'ON CONFLICT("id") DO NOTHING',
      ['my content'],
    ));
  });

  test('can use a custom conflict clause with do nothing', () async {
    await db.into(db.todosTable).insert(
          TodosTableCompanion.insert(content: 'my content'),
          onConflict: DoNothing(
            target: [db.todosTable.content],
          ),
        );

    verify(executor.executeSql(
      'INSERT INTO "todos" ("content") VALUES (?1) '
      'ON CONFLICT("content") DO NOTHING',
      ['my content'],
    ));
  });

  test('insertOnConflictUpdate', () async {
    when(executor.execute(any)).thenAnswer((_) async {
      return queryResult(null, lastInsertRowId: 3);
    });

    final id = await db.into(db.todosTable).insertOnConflictUpdate(
        TodosTableCompanion.insert(
            content: 'content', id: const Value(RowId(3))));

    verify(executor.executeSql(
      'INSERT INTO "todos" ("id","content") VALUES (?1,?2) '
      'ON CONFLICT("id") DO UPDATE SET "id" = ?1,"content" = ?2',
      [3, 'content'],
    ));
    expect(id, 3);
  });

  test('can access excluded row in upsert', () async {
    await db.into(db.todosTable).insert(
          TodosTableCompanion.insert(content: 'content'),
          onConflict: DoUpdate.withExcluded(
            (old, excluded) => TodosTableCompanion.custom(
              content: old.content + excluded.content,
            ),
          ),
        );

    verify(executor.executeSql(
      'INSERT INTO "todos" ("content") VALUES (?1) '
      'ON CONFLICT("id") DO UPDATE '
      'SET "content" = "todos"."content" || "excluded"."content"',
      ['content'],
    ));
  });

  test('can access excluded row in upsert with where', () async {
    await db.into(db.todosTable).insert(
          TodosTableCompanion.insert(content: 'content'),
          onConflict: DoUpdate.withExcluded(
              (old, excluded) => TodosTableCompanion.custom(
                    content: old.content + excluded.content,
                  ),
              where: (old, excluded) => old.title.equalsExp(excluded.title)),
        );

    verify(executor.executeSql(
      'INSERT INTO "todos" ("content") VALUES (?1) '
      'ON CONFLICT("id") DO UPDATE '
      'SET "content" = "todos"."content" || "excluded"."content" '
      'WHERE "todos"."title" = "excluded"."title"',
      ['content'],
    ));
  });

  test('applies implicit type converter', () async {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          description: 'description',
          priority: const Value(CategoryPriority.medium),
        ));

    verify(executor.executeSql(
      'INSERT INTO "categories" ("desc","priority") VALUES (?1,?2)',
      ['description', 1],
    ));
  });

  test('generates RETURNING clauses', () async {
    when(executor.execute(any)).thenAnswer((_) async {
      return queryResult(affectedRows: 1, [
        {
          'id': 1,
          'desc': 'description',
          'description_in_upper_case': 'DESCRIPTION',
          'priority': 1,
        },
      ]);
    });

    await db.into(db.categories).insertReturning(CategoriesCompanion.insert(
          description: 'description',
          priority: const Value(CategoryPriority.medium),
        ));

    verify(executor.executeSql(
      'INSERT INTO "categories" ("desc","priority") VALUES (?1,?2) RETURNING *',
      ['description', 1],
    ));
  });

  group('insert from select', () {
    test('with simple select statement', () async {
      final query = db.select(db.categories);
      await db.into(db.categories).insertFromSelect(query, columns: {
        db.categories.description: db.categories.description,
        db.categories.priority: db.categories.priority,
      });

      verify(executor.executeSql(
        'WITH _source AS (SELECT "id" AS "id","desc" AS "desc","priority" AS "priority","description_in_upper_case" AS "description_in_upper_case" FROM "categories")'
        'INSERT INTO "categories" ("desc","priority") '
        'SELECT _source."desc",_source."priority"',
        isEmpty,
      ));
    });

    test('with join', () async {
      final amountOfTodos = db.todosTable.id.count();
      final newDescription = db.categories.description + amountOfTodos.cast();
      final query = db
          .selectOnly(db.todosTable)
          .innerJoin(db.categories,
              on: db.categories.id.equalsExp(db.todosTable.category))
          .groupBy([db.categories.id]).addColumns(
              [newDescription, db.categories.priority]);

      await db.into(db.categories).insertFromSelect(query, columns: {
        db.categories.description: newDescription,
        db.categories.priority: db.categories.priority,
      });

      verify(executor.executeSql(
        'WITH _source AS (SELECT '
        '"categories"."desc" || CAST((COUNT("todos"."id")) AS TEXT) AS "c0",'
        '"categories"."priority" AS "c1" '
        'FROM "todos" '
        'INNER JOIN "categories" ON "categories"."id" = "todos"."category" '
        'GROUP BY "categories"."id")'
        'INSERT INTO "categories" ("desc","priority") SELECT _source."c0",_source."c1"',
        isEmpty,
      ));
    });

    test('with on conflict clause', () async {
      final query = db.select(db.categories);

      await db.into(db.categories).insertFromSelect(
            query,
            columns: {
              db.categories.description: db.categories.description,
              db.categories.priority: db.categories.priority,
            },
            onConflict: DoUpdate((old) => CategoriesCompanion.custom(
                  description: old.description,
                )),
          );

      verify(executor.executeSql(
        'WITH _source AS (SELECT "id" AS "id","desc" AS "desc","priority" AS "priority","description_in_upper_case" AS "description_in_upper_case" FROM "categories")'
        'INSERT INTO "categories" ("desc","priority") '
        'SELECT _source."desc",_source."priority" WHERE TRUE '
        'ON CONFLICT("id") DO UPDATE SET "desc" = "desc"',
        isEmpty,
      ));
    });
  });
}
