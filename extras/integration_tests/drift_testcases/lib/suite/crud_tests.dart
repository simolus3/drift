import 'package:test/test.dart';

import '../tests.dart';

void crudTests(TestExecutor executor) {
  test('inserting updates a select stream', () async {
    final db = Database(executor.createConnection());
    final friends = db.friendsOf(1).watch().asBroadcastStream();

    final a = await db.getUserById(1);
    final b = await db.getUserById(2);

    expect(await friends.first, isEmpty);

    await db.makeFriends(a, b);
    await expectLater(friends, emits(equals(<User>[b])));

    await executor.clearDatabaseAndClose(db);
  });

  test('update row', () async {
    final db = Database(executor.createConnection());

    await (db.update(db.users)..where((tbl) => tbl.id.equals(1)))
        .write(UsersCompanion(name: Value("Jack")));
    final updatedUser = await db.getUserById(1);

    expect(updatedUser.name, equals('Jack'));
    await executor.clearDatabaseAndClose(db);
  });

  test('insert duplicate', () async {
    final db = Database(executor.createConnection());

    await expectLater(
      db.into(db.users).insert(marcell),
      throwsA(
        toString(anyOf(
          // sqlite3 and postgres
          matches(RegExp(r'unique constraint', caseSensitive: false)),
          // mariadb
          matches(RegExp(r'duplicate entry', caseSensitive: false)),
        )),
      ),
    );
    await executor.clearDatabaseAndClose(db);
  });

  test('insert on conflict update', () async {
    final db = Database(executor.createConnection());

    await db.into(db.users).insertOnConflictUpdate(marcell);
    final updatedUser = await db.getUserById(1);

    expect(updatedUser.name, equals('Marcell'));
    await executor.clearDatabaseAndClose(db);
  });

  test('insert mode', () async {
    final db = Database(executor.createConnection());
    if (db.executor.dialect == SqlDialect.postgres) {
      await expectLater(
          db.into(db.users).insert(marcell, mode: InsertMode.insertOrReplace),
          throwsA(isA<ArgumentError>()));
    }
    await executor.clearDatabaseAndClose(db);
  });

  test('supports RETURNING', () async {
    final db = Database(executor.createConnection());
    final result = await db.returning(1, 2, true);

    expect(result,
        [Friendship(firstUser: 1, secondUser: 2, reallyGoodFriends: true)]);
    await executor.clearDatabaseAndClose(db);
  },
      skip: executor.supportsReturning
          ? null
          : 'Runner does not support RETURNING');

  test('IN ? expressions can be expanded', () async {
    // regression test for https://github.com/simolus3/drift/issues/156
    final db = Database(executor.createConnection());
    final result = await db.usersById([1, 2, 3]).get();

    expect(result.map((u) => u.name), ['Dash', 'Duke', 'Go Gopher']);
    await executor.clearDatabaseAndClose(db);
  });

  test('nested results', () async {
    final db = Database(executor.createConnection());

    final a = await db.getUserById(1);
    final b = await db.getUserById(2);

    await db.makeFriends(a, b, goodFriends: true);
    final result = await db.friendshipsOf(a.id).getSingle();

    expect(result, FriendshipsOfResult(reallyGoodFriends: true, user: b));
    await executor.clearDatabaseAndClose(db);
  });

  test('runCustom with args', () async {
    // https://github.com/simolus3/drift/issues/406
    final db = Database(executor.createConnection());

    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    await db.customStatement(
        switch (db.executor.dialect) {
          SqlDialect.postgres =>
            r'INSERT INTO friendships (first_user, second_user) VALUES ($1, $2)',
          SqlDialect.mariadb =>
            r'INSERT INTO friendships (first_user, second_user) VALUES (?, ?)',
          _ =>
            r'INSERT INTO friendships (first_user, second_user) VALUES (?1, ?2)',
        },
        <int>[1, 2]);

    expect(await db.friendsOf(1).get(), isNotEmpty);
    await executor.clearDatabaseAndClose(db);
  });

  group('bind variable', () {
    late Database database;

    setUp(() => database = Database(executor.createConnection()));
    tearDown(() => executor.clearDatabaseAndClose(database));

    Future<T?> evaluate<T extends Object>(Expression<T> expr) async {
      late final Expression<T> effectiveExpr;
      final dialect = database.executor.dialect;
      if (dialect == SqlDialect.postgres || dialect == SqlDialect.mariadb) {
        // 'SELECT'ing values that don't come from a table return as String
        // by default, so we need to explicitly cast it to the expected type
        // https://www.postgresql.org/docs/current/typeconv-select.html
        effectiveExpr = expr.cast<T>();
      } else {
        effectiveExpr = expr;
      }

      final query = database.selectOnly(database.users)
        ..addColumns([effectiveExpr])
        ..limit(1);
      final row = await query.getSingle();
      final columnValue = row.read(effectiveExpr);

      expect(
        columnValue,
        TypeMatcher<T?>(),
        reason:
            "Type of the input argument does not match the returned column value",
      );
      return columnValue;
    }

    test('null', () {
      expect(evaluate(Variable<String>(null)), completion(isNull));
    });

    test('string', () {
      expect(evaluate(Variable<String>('foo bar')), completion('foo bar'));
      expect(evaluate(Variable<String>('')), completion(''));
    });

    test('boolean', () {
      expect(evaluate(Variable<bool>(true)), completion(isTrue));
      expect(evaluate(Variable<bool>(false)), completion(isFalse));
    });

    test('int', () {
      expect(evaluate(Variable<double>(42)), completion(42));
    });

    test('double', () {
      expect(evaluate(Variable<double>(3.14)), completion(3.14));
    });

    test('Uint8List', () {
      final list = Uint8List.fromList(List.generate(12, (index) => index));

      expect(evaluate(Variable<Uint8List>(list)), completion(list));
    });
  },
      skip: executor.hackyVariables
          ? 'Not properly supported by this implementation'
          : null);
}
