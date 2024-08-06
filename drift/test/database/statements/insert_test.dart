import 'package:drift/drift.dart' hide isNull;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  late TodoDb db;
  late MockExecutor executor;
  late MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();

    final connection = createConnection(executor, streamQueries);
    db = TodoDb(connection);
  });

  test('generates insert statements', () async {
    await db.into(db.todosTable).insert(const TodosTableCompanion(
          content: Value('Implement insert statements'),
          title: Value.absent(),
        ));

    verify(executor.runInsert('INSERT INTO "todos" ("content") VALUES (?)',
        ['Implement insert statements']));
  });

  test('can insert floating point values', () async {
    // regression test for https://github.com/simolus3/drift/issues/30
    await db.into(db.tableWithoutPK).insert(
        CustomRowClass.map(42, 3.1415, custom: MyCustomObject('custom'))
            .toInsertable());

    verify(executor.runInsert(
        'INSERT INTO "table_without_p_k" '
        '("not_really_an_id", "some_float", "web_safe_int", "custom") '
        'VALUES (?, ?, ?, ?)',
        [42, 3.1415, isNull, anything]));
  });

  test('can insert BigInt values', () async {
    await db.into(db.tableWithoutPK).insert(CustomRowClass.map(42, 0,
            webSafeInt: BigInt.one, custom: MyCustomObject('custom'))
        .toInsertable());

    verify(executor.runInsert(
        'INSERT INTO "table_without_p_k" '
        '("not_really_an_id", "some_float", "web_safe_int", "custom") '
        'VALUES (?, ?, ?, ?)',
        [42, 0.0, BigInt.one, anything]));
  });

  test('generates insert or replace statements', () async {
    await db.into(db.todosTable).insert(
        const TodoEntry(
          id: RowId(113),
          content: 'Done',
        ),
        mode: InsertMode.insertOrReplace);

    verify(executor.runInsert(
        'INSERT OR REPLACE INTO "todos" ("id", "content") VALUES (?, ?)',
        [113, 'Done']));
  });

  test('generates DEFAULT VALUES statement when otherwise empty', () async {
    await db.into(db.pureDefaults).insert(const PureDefaultsCompanion());

    verify(
        executor.runInsert('INSERT INTO "pure_defaults" DEFAULT VALUES', []));
  });

  test('notifies stream queries on inserts', () async {
    await db.into(db.users).insert(UsersCompanion(
          name: const Value('User McUserface'),
          isAwesome: const Value(true),
          profilePicture: Value(Uint8List(0)),
        ));

    verify(streamQueries.handleTableUpdates(
        {const TableUpdate('users', kind: UpdateKind.insert)}));
  });

  test('notifies stream queries on insertReturning', () async {
    when(executor.runSelect(any, any)).thenAnswer((_) {
      return Future.value([
        {
          'id': 5,
          'name': 'User McUserface',
          'is_awesome': true,
          'profile_picture': Uint8List(0),
          'creation_time': DateTime.now().millisecondsSinceEpoch,
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

  group('enforces integrity', () {
    test('for regular inserts', () async {
      InvalidDataException exception;
      try {
        await db.into(db.todosTable).insert(
              const TodosTableCompanion(
                // has a min length of 4
                title: Value('s'),
              ),
            );
        fail('inserting invalid data did not throw');
      } on InvalidDataException catch (e) {
        exception = e;
      }

      expect(exception.toString(), startsWith('InvalidDataException'));
    });

    test("for upserts that aren't valid inserts", () {
      expect(
        () {
          return db
              .into(db.todosTable)
              // content would be required
              .insertOnConflictUpdate(const TodosTableCompanion());
        },
        throwsA(isA<InvalidDataException>()),
      );
    });

    test("for upserts that aren't valid updates", () {
      expect(
        () {
          final insert = TodosTableCompanion.insert(content: 'content');
          const update = TodosTableCompanion(title: Value('s'));
          return db
              .into(db.todosTable)
              .insert(insert, onConflict: DoUpdate((_) => update));
        },
        throwsA(isA<InvalidDataException>()),
      );
    });

    test('can provide null value for column with additional checks', () async {
      await db.todosTable.insertOne(
          TodosTableCompanion.insert(content: 'content', title: Value(null)));

      verify(executor.runInsert(
          'INSERT INTO "todos" ("title", "content") VALUES (?, ?)',
          [null, 'content']));
    });
  });

  test('reports auto-increment id', () {
    when(executor.runInsert(any, any)).thenAnswer((_) => Future.value(42));

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

    verify(executor.runInsert(
      'INSERT INTO "table_without_p_k" ("not_really_an_id", "some_float", "custom") '
      'VALUES (?, ?, ?)',
      [3, 3.14, matches(uuidRegex)],
    ));
  });

  test('escaped when column name is keyword', () async {
    await db.into(db.pureDefaults).insert(
        PureDefaultsCompanion.insert(txt: Value(MyCustomObject('foo'))));

    verify(executor.runInsert(
        'INSERT INTO "pure_defaults" ("insert") VALUES (?)', ['foo']));
  });

  test('can insert custom companions', () async {
    await db.into(db.users).insert(UsersCompanion.custom(
        isAwesome: const Constant(true),
        name: const Variable('User name'),
        profilePicture: const CustomExpression('_custom_'),
        creationTime: currentDateAndTime));

    verify(
      executor.runInsert(
        'INSERT INTO "users" ("name", "is_awesome", "profile_picture", "creation_time") '
        'VALUES (?, 1, _custom_, '
        "CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))",
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

    verify(executor.runInsert(
      'INSERT INTO "todos" ("content") VALUES (?) '
      'ON CONFLICT("id") DO UPDATE SET "content" = ? || "content"',
      argThat(equals(['my content', 'important: '])),
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

    verify(executor.runInsert(
      'INSERT INTO "todos" ("content") VALUES (?) '
      'ON CONFLICT("id") DO UPDATE SET "content" = ? || "content" '
      'WHERE "category" = ?',
      argThat(equals(['my content', 'important: ', 1])),
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

    verify(executor.runInsert(
      'INSERT INTO "todos" ("content") VALUES (?) '
      'ON CONFLICT("id")WHERE "category" = ? '
      'DO UPDATE SET "content" = ? || "content"',
      argThat(equals(['my content', 1, 'important: '])),
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

    verify(executor.runInsert(
      'INSERT INTO "todos" ("content") VALUES (?) '
      'ON CONFLICT DO UPDATE SET "content" = ? || "content"',
      argThat(equals(['my content', 'important: '])),
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

      verify(executor.runInsert(
        'INSERT INTO "todos" ("content") VALUES (?) '
        'ON CONFLICT("id") DO UPDATE SET "content" = ? || "content" '
        'ON CONFLICT("content") DO UPDATE SET "content" = ? || "content"',
        argThat(equals(['my content', 'important: ', 'second: '])),
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

      verify(executor.runInsert(
        'INSERT INTO "todos" ("content") VALUES (?) '
        'ON CONFLICT("id") DO UPDATE SET "content" = ? || "content" '
        'ON CONFLICT("content") DO NOTHING',
        argThat(equals(['my content', 'important: '])),
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

      verify(executor.runInsert(
        'INSERT INTO "todos" ("content") VALUES (?) '
        'ON CONFLICT("id") DO UPDATE SET "content" = ? || "content" '
        'ON CONFLICT("content") DO NOTHING',
        argThat(equals(['my content', 'important: '])),
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

      verify(executor.runInsert(
        'INSERT INTO "todos" ("content") VALUES (?) '
        'ON CONFLICT("id") DO UPDATE SET "content" = ? || "content" '
        'WHERE "category" = ? '
        'ON CONFLICT("content") DO UPDATE SET "content" = ? || "content" '
        'WHERE "category" = ?',
        argThat(equals(['my content', 'important: ', 1, 'second: ', 1])),
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

    verify(executor.runInsert(
      'INSERT INTO "todos" ("content") VALUES (?) '
      'ON CONFLICT("content") DO UPDATE SET "content" = ?',
      argThat(equals(['my content', 'changed'])),
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

    verify(executor.runInsert(
      'INSERT INTO "todos" ("content") VALUES (?) '
      'ON CONFLICT("content") DO UPDATE SET "content" = ? '
      'WHERE "content" = "title"',
      argThat(equals(['my content', 'changed'])),
    ));
  });

  test('can use do nothing on upsert', () async {
    await db.into(db.todosTable).insert(
          TodosTableCompanion.insert(content: 'my content'),
          onConflict: DoNothing(),
        );

    verify(executor.runInsert(
      'INSERT INTO "todos" ("content") VALUES (?) '
      'ON CONFLICT("id") DO NOTHING',
      argThat(equals(['my content'])),
    ));
  });

  test('can use a custom conflict clause with do nothing', () async {
    await db.into(db.todosTable).insert(
          TodosTableCompanion.insert(content: 'my content'),
          onConflict: DoNothing(
            target: [db.todosTable.content],
          ),
        );

    verify(executor.runInsert(
      'INSERT INTO "todos" ("content") VALUES (?) '
      'ON CONFLICT("content") DO NOTHING',
      argThat(equals(['my content'])),
    ));
  });

  test('insertOnConflictUpdate', () async {
    when(executor.runInsert(any, any)).thenAnswer((_) => Future.value(3));

    final id = await db.into(db.todosTable).insertOnConflictUpdate(
        TodosTableCompanion.insert(
            content: 'content', id: const Value(RowId(3))));

    verify(executor.runInsert(
      'INSERT INTO "todos" ("id", "content") VALUES (?, ?) '
      'ON CONFLICT("id") DO UPDATE SET "id" = ?, "content" = ?',
      [3, 'content', 3, 'content'],
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

    verify(executor.runInsert(
      'INSERT INTO "todos" ("content") VALUES (?) '
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

    verify(executor.runInsert(
      'INSERT INTO "todos" ("content") VALUES (?) '
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

    verify(executor.runInsert(
      'INSERT INTO "categories" ("desc", "priority") VALUES (?, ?)',
      ['description', 1],
    ));
  });

  test('generates RETURNING clauses', () async {
    when(executor.runSelect(any, any)).thenAnswer(
      (_) => Future.value([
        {
          'id': 1,
          'desc': 'description',
          'description_in_upper_case': 'DESCRIPTION',
          'priority': 1,
        },
      ]),
    );

    await db.into(db.categories).insertReturning(CategoriesCompanion.insert(
          description: 'description',
          priority: const Value(CategoryPriority.medium),
        ));

    verify(executor.runSelect(
      'INSERT INTO "categories" ("desc", "priority") VALUES (?, ?) RETURNING *',
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

      verify(executor.runInsert(
        'WITH _source AS (SELECT * FROM "categories") INSERT INTO "categories" '
        '("desc", "priority") SELECT "desc", "priority" FROM _source',
        argThat(isEmpty),
      ));
    });

    test('with join', () async {
      final amountOfTodos = db.todosTable.id.count();
      final newDescription = db.categories.description + amountOfTodos.cast();
      final query = db.selectOnly(db.todosTable)
        ..join([
          innerJoin(
              db.categories, db.categories.id.equalsExp(db.todosTable.category))
        ])
        ..groupBy([db.categories.id])
        ..addColumns([newDescription, db.categories.priority]);

      await db.into(db.categories).insertFromSelect(query, columns: {
        db.categories.description: newDescription,
        db.categories.priority: db.categories.priority,
      });

      verify(executor.runInsert(
        'WITH _source AS (SELECT '
        '"categories"."desc" || CAST(COUNT("todos"."id") AS TEXT) AS "c0", '
        '"categories"."priority" AS "categories.priority" '
        'FROM "todos" '
        'INNER JOIN "categories" ON "categories"."id" = "todos"."category" '
        'GROUP BY "categories"."id") '
        'INSERT INTO "categories" ("desc", "priority") '
        'SELECT "c0", "categories.priority" FROM _source',
        argThat(isEmpty),
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

      verify(executor.runInsert(
        'WITH _source AS (SELECT * FROM "categories") INSERT INTO "categories" '
        '("desc", "priority") SELECT "desc", "priority" FROM _source '
        'ON CONFLICT("id") DO UPDATE SET "desc" = "desc"',
        argThat(isEmpty),
      ));
    });
  });

  group('on table instances', () {
    test('insert', () async {
      await db.categories
          .insert()
          .insert(CategoriesCompanion.insert(description: 'description'));

      verify(executor.runInsert(
          'INSERT INTO "categories" ("desc") VALUES (?)', ['description']));
    });

    test('insertOne', () async {
      await db.categories.insertOne(
          CategoriesCompanion.insert(description: 'description'),
          mode: InsertMode.insertOrReplace);

      verify(executor.runInsert(
          'INSERT OR REPLACE INTO "categories" ("desc") VALUES (?)',
          ['description']));
    });

    test('insertAll', () async {
      await db.categories.insertAll(
        [
          CategoriesCompanion.insert(description: 'first description'),
          CategoriesCompanion.insert(description: 'another description'),
        ],
        mode: InsertMode.insertOrAbort,
        onConflict: DoUpdate((row) =>
            CategoriesCompanion.custom(priority: row.priority + Constant(1))),
      );

      verify(executor.transactions.runBatched(BatchedStatements(
        [
          'pragma defer_foreign_keys = on;',
          'INSERT OR ABORT INTO "categories" ("desc") VALUES (?) '
              'ON CONFLICT("id") DO UPDATE SET "priority" = "priority" + 1'
        ],
        [
          ArgumentsForBatchedStatement(0, []),
          ArgumentsForBatchedStatement(1, ['first description']),
          ArgumentsForBatchedStatement(1, ['another description']),
        ],
      )));
    });

    test('insertOnConflictUpdate', () async {
      when(executor.runSelect(any, any)).thenAnswer(
        (_) => Future.value([
          {
            'id': 1,
            'desc': 'description',
            'description_in_upper_case': 'DESCRIPTION',
            'priority': 1,
          },
        ]),
      );

      final row = await db.categories.insertReturning(
          CategoriesCompanion.insert(description: 'description'));
      expect(
        row,
        const Category(
          id: RowId(1),
          description: 'description',
          descriptionInUpperCase: 'DESCRIPTION',
          priority: CategoryPriority.medium,
        ),
      );

      verify(executor.runSelect(
        'INSERT INTO "categories" ("desc") VALUES (?) RETURNING *',
        ['description'],
      ));
    });
  });
}
