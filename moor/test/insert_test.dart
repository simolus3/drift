//@dart=2.9
import 'package:moor/moor.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;
  MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();

    final connection = createConnection(executor, streamQueries);
    db = TodoDb.connect(connection);
  });

  test('generates insert statements', () async {
    await db.into(db.todosTable).insert(const TodosTableCompanion(
          content: Value('Implement insert statements'),
          title: Value.absent(),
        ));

    verify(executor.runInsert('INSERT INTO todos (content) VALUES (?)',
        ['Implement insert statements']));
  });

  test('can insert floating point values', () async {
    // regression test for https://github.com/simolus3/moor/issues/30
    await db.into(db.tableWithoutPK).insert(
        TableWithoutPKData(notReallyAnId: 42, someFloat: 3.1415, custom: null));

    verify(executor.runInsert(
        'INSERT INTO table_without_p_k '
        '(not_really_an_id, some_float, custom) VALUES (?, ?, ?)',
        [42, 3.1415, anything]));
  });

  test('generates insert or replace statements', () async {
    await db.into(db.todosTable).insert(
        TodoEntry(
          id: 113,
          content: 'Done',
        ),
        mode: InsertMode.insertOrReplace);

    verify(executor.runInsert(
        'INSERT OR REPLACE INTO todos (id, content) VALUES (?, ?)',
        [113, 'Done']));
  });

  test('generates DEFAULT VALUES statement when otherwise empty', () async {
    await db.into(db.pureDefaults).insert(const PureDefaultsCompanion());

    verify(executor.runInsert('INSERT INTO pure_defaults DEFAULT VALUES', []));
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

  group('enforces integrity', () {
    test('for regular inserts', () async {
      InvalidDataException exception;
      try {
        await db.into(db.todosTable).insert(
              const TodosTableCompanion(
                // not declared as nullable in table definition
                content: Value(null),
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
          const update = TodosTableCompanion(content: Value(null));
          return db
              .into(db.todosTable)
              .insert(insert, onConflict: DoUpdate((_) => update));
        },
        throwsA(isA<InvalidDataException>()),
      );
    });
  });

  test("doesn't allow writing null rows", () {
    expect(
      () {
        return db.into(db.todosTable).insert(null);
      },
      throwsA(const TypeMatcher<InvalidDataException>().having(
          (e) => e.message, 'message', contains('Cannot write null row'))),
    );
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
      'INSERT INTO table_without_p_k (not_really_an_id, some_float, custom) '
      'VALUES (?, ?, ?)',
      [3, 3.14, matches(uuidRegex)],
    ));
  });

  test('escaped when column name is keyword', () async {
    await db
        .into(db.pureDefaults)
        .insert(PureDefaultsCompanion.insert(txt: const Value('foo')));

    verify(executor
        .runInsert('INSERT INTO pure_defaults ("insert") VALUES (?)', ['foo']));
  });

  test('can insert custom companions', () async {
    await db.into(db.users).insert(UsersCompanion.custom(
        isAwesome: const Constant(true),
        name: const Variable('User name'),
        profilePicture: const CustomExpression('_custom_'),
        creationTime: currentDateAndTime));

    verify(
      executor.runInsert(
        'INSERT INTO users (name, is_awesome, profile_picture, creation_time) '
        "VALUES (?, 1, _custom_, strftime('%s', CURRENT_TIMESTAMP))",
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
      'INSERT INTO todos (content) VALUES (?) '
      'ON CONFLICT(id) DO UPDATE SET content = ? || content',
      argThat(equals(['my content', 'important: '])),
    ));
  });

  test('can use a custom conflict clause', () async {
    await db.into(db.todosTable).insert(
          TodosTableCompanion.insert(content: 'my content'),
          onConflict: DoUpdate(
            (old) => TodosTableCompanion.insert(content: 'changed'),
            target: [db.todosTable.content],
          ),
        );

    verify(executor.runInsert(
      'INSERT INTO todos (content) VALUES (?) '
      'ON CONFLICT(content) DO UPDATE SET content = ?',
      argThat(equals(['my content', 'changed'])),
    ));
  });

  test('insertOnConflictUpdate', () async {
    when(executor.runInsert(any, any)).thenAnswer((_) => Future.value(3));

    final id = await db.into(db.todosTable).insertOnConflictUpdate(
        TodosTableCompanion.insert(content: 'content', id: const Value(3)));

    verify(executor.runInsert(
      'INSERT INTO todos (id, content) VALUES (?, ?) '
      'ON CONFLICT(id) DO UPDATE SET id = ?, content = ?',
      [3, 'content', 3, 'content'],
    ));
    expect(id, 3);
  });

  test('applies implicit type converter', () async {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          description: 'description',
          priority: const Value(CategoryPriority.medium),
        ));

    verify(executor.runInsert(
      'INSERT INTO categories ("desc", priority) VALUES (?, ?)',
      ['description', 1],
    ));
  });
}
