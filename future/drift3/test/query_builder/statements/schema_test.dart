import 'package:drift3_preview/drift.dart';
import 'package:drift3_preview/internal/versioned_schema.dart';
import 'package:drift_postgres/src/drift3_preview/drift_postgres.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils.dart';
import '../../test_utils/mocks.dart';

void main() {
  late TodoDb db;
  late MockSession mockExecutor;

  setUp(() {
    mockExecutor = MockSession();
    db = TodoDb(createConnection(mockExecutor));

    // Disable migrations by default
    when(
      mockExecutor.schemaVersion,
    ).thenAnswer((_) => Future.value(db.schemaVersion));
  });

  group('Migrations', () {
    test('creates all tables', () async {
      final sql = <String>[];

      when(mockExecutor.schemaVersion).thenAnswer((_) => Future.value(0));
      when(mockExecutor.execute(any)).thenAnswer((i) async {
        sql.add((i.positionalArguments[0] as StatementInfo).sql);
        return queryResult([]);
      });

      await db.initialize();

      expect(
        sql[0],
        'CREATE TABLE IF NOT EXISTS "categories" '
        '("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,'
        '"desc" TEXT NOT NULL UNIQUE,'
        '"priority" INTEGER NOT NULL DEFAULT 0,'
        '"description_in_upper_case" TEXT NOT NULL GENERATED ALWAYS AS '
        '(UPPER("desc")) VIRTUAL'
        ');',
      );

      expect(
        sql[1],
        'CREATE TABLE IF NOT EXISTS "todos" '
        '("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,'
        '"title" TEXT,'
        '"content" TEXT NOT NULL,'
        '"target_date" TEXT UNIQUE,'
        '"category" INTEGER REFERENCES categories (id)DEFERRABLE INITIALLY DEFERRED,'
        '"status" TEXT,'
        'UNIQUE ("title","category"),UNIQUE ("title","target_date"));',
      );

      expect(
        sql[2],
        'CREATE TABLE IF NOT EXISTS "users" ('
        '"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,'
        '"name" TEXT NOT NULL UNIQUE,'
        '"is_awesome" INTEGER NOT NULL DEFAULT 1 CHECK ("is_awesome" IN (0, 1)),'
        '"profile_picture" BLOB NOT NULL,'
        '"creation_time" TEXT NOT NULL DEFAULT (CURRENT_TIMESTAMP) '
        'CHECK(julianday("creation_time") > julianday(\'1950-01-01T00:00:00.000Z\'))'
        ');',
      );

      expect(
        sql[3],
        'CREATE TABLE IF NOT EXISTS "shared_todos" ('
        '"todo" INTEGER NOT NULL,'
        '"user" INTEGER NOT NULL,'
        'PRIMARY KEY ("todo","user"),'
        'FOREIGN KEY (todo) REFERENCES todos(id),'
        'FOREIGN KEY (user) REFERENCES users(id)'
        ');',
      );

      expect(
        sql[4],
        'CREATE TABLE IF NOT EXISTS "table_with_every_column_type" ('
        '"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,'
        '"a_bool" INTEGER CHECK ("a_bool" IN (0, 1)),'
        '"a_date_time" TEXT,'
        '"a_text" TEXT,'
        '"an_int" INTEGER,'
        '"an_int64" INTEGER,'
        '"a_real" REAL,'
        '"a_blob" BLOB,'
        '"an_int_enum" INTEGER,'
        '"insert" TEXT'
        ');',
      );

      expect(
        sql[5],
        'CREATE TABLE IF NOT EXISTS '
        '"table_without_p_k" ('
        '"not_really_an_id" INTEGER NOT NULL,'
        '"some_float" REAL NOT NULL,'
        '"web_safe_int" INTEGER,'
        '"custom" TEXT NOT NULL'
        ');',
      );

      expect(
        sql[6],
        'CREATE TABLE IF NOT EXISTS "pure_defaults" ('
        '"insert" TEXT,'
        'PRIMARY KEY ("insert")'
        ');',
      );

      expect(
        sql[7],
        'CREATE TABLE IF NOT EXISTS "with_custom_type" ('
        '"id" text NOT NULL'
        ');',
      );

      expect(
        sql[9],
        'CREATE VIEW IF NOT EXISTS "category_todo_count_view"'
        '("category_id","description","item_count") AS SELECT '
        '"t1"."id",'
        '"t1"."desc" || \'!\','
        'COUNT("t0"."id") '
        'FROM "categories" AS "t1" '
        'INNER JOIN "todos" AS "t0" '
        'ON "t0"."category" = "t1"."id" '
        'GROUP BY "t1"."id"',
      );

      expect(
        sql[10],
        'CREATE VIEW IF NOT EXISTS "todo_with_category_view"'
        '("title","desc") AS SELECT '
        '"t0"."title",'
        '"t1"."desc" '
        'FROM "todos" AS "t0" '
        'INNER JOIN "categories" AS "t1" '
        'ON "t1"."id" = "t0"."category"',
      );

      expect(
        sql[11],
        'CREATE INDEX categories_desc ON categories ("desc" DESC, priority)',
      );
    });

    test('creates individual tables', () async {
      await db.createMigrator().createTable(db.users);

      verify(
        mockExecutor.executeSql(
          'CREATE TABLE IF NOT EXISTS "users" ('
          '"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,'
          '"name" TEXT NOT NULL UNIQUE,'
          '"is_awesome" INTEGER NOT NULL DEFAULT 1 CHECK ("is_awesome" IN (0, 1)),'
          '"profile_picture" BLOB NOT NULL,'
          '"creation_time" TEXT NOT NULL DEFAULT (CURRENT_TIMESTAMP) '
          'CHECK(julianday("creation_time") > julianday(\'1950-01-01T00:00:00.000Z\'))'
          ');',
        ),
      );
    });

    group('creates tables with custom types', () {
      test('sqlite3', () async {
        await db.createMigrator().createTable(db.withCustomType);

        verify(
          mockExecutor.executeSql(
            'CREATE TABLE IF NOT EXISTS "with_custom_type" ("id" text NOT NULL);',
            [],
          ),
        );
      });

      test('postgres', () async {
        db = TodoDb(
          createConnection(mockExecutor, dialect: PostgresDialect.new),
        );

        await db.createMigrator().createTable(db.withCustomType);
        verify(
          mockExecutor.executeSql(
            'CREATE TABLE IF NOT EXISTS "with_custom_type" ("id" uuid NOT NULL);',
            [],
          ),
        );
      });
    });

    test('creates views through create()', () async {
      await db.createMigrator().create(db.categoryTodoCountView);

      verify(
        mockExecutor.executeSql(
          'CREATE VIEW IF NOT EXISTS "category_todo_count_view"'
          '("category_id","description","item_count") AS SELECT '
          '"t1"."id",'
          '"t1"."desc" || \'!\','
          'COUNT("t0"."id") '
          'FROM "categories" AS "t1" '
          'INNER JOIN "todos" AS "t0" '
          'ON "t0"."category" = "t1"."id" '
          'GROUP BY "t1"."id"',
          [],
        ),
      );
    });

    test('drops tables', () async {
      await db.createMigrator().deleteTable('users');

      verify(mockExecutor.executeSql('DROP TABLE IF EXISTS "users";'));
    });

    test('drops indices', () async {
      await db.createMigrator().drop(Index('desc', CustomComponent('foo')));

      verify(mockExecutor.executeSql('DROP INDEX IF EXISTS "desc";'));
    });

    test('drops triggers', () async {
      await db.createMigrator().drop(
        Trigger('my_trigger', CustomComponent('foo')),
      );

      verify(mockExecutor.executeSql('DROP TRIGGER IF EXISTS "my_trigger";'));
    });

    test('adds columns', () async {
      await db.createMigrator().addColumn(db.users, db.users.isAwesome);

      verify(
        mockExecutor.executeSql(
          'ALTER TABLE "users" ADD COLUMN '
          '"is_awesome" INTEGER NOT NULL DEFAULT 1 '
          'CHECK ("is_awesome" IN (0, 1));',
        ),
      );
    });

    test('renames columns', () async {
      await db.createMigrator().renameColumn(
        db.users,
        'my name',
        db.users.name,
      );

      verify(
        mockExecutor.executeSql(
          'ALTER TABLE "users" RENAME COLUMN "my name" TO "name";',
        ),
      );
    });
  });

  test('custom statements', () async {
    await db.customStatement('some custom statement');
    verify(mockExecutor.executeSql('some custom statement'));
  });

  test('upgrading a database without schema migration throws', () async {
    when(mockExecutor.schemaVersion).thenAnswer((_) => Future.value(1));
    final db = _DefaultDb(createConnection(mockExecutor));

    expect(() => db.initialize(), throwsA(const TypeMatcher<Exception>()));
  });

  test('can use transactions inside schema callbacks', () async {
    when(mockExecutor.schemaVersion).thenAnswer((_) => Future.value(2));

    db
      ..schemaVersion = 3
      ..migration = MigrationStrategy(
        onUpgrade: (m, from, to) async {
          await db.transaction(() async {
            await m.createTable(db.users);
          });
        },
      );

    await db.initialize();
    verify(mockExecutor.begin(any));
    verify(mockExecutor.transactions.execute(any));
    verifyNever(mockExecutor.execute(any));
  });

  test('removes variables in `CREATE TABLE` statements', () async {
    final executor = MockSession();
    final db = _DefaultDb(createConnection(executor));

    late TableColumn<int> column;
    column = TableColumn<int>(
      name: 'foo',
      sqlType: BuiltinDriftType.int,
      constraints: () => [
        ColumnCheckConstraint(column.isLessThan(const Variable(3))),
      ],
    );
    final table = VersionedTable(
      entityName: 'foo',
      isStrict: false,
      withoutRowId: false,
      columns: [(_) => column],
      tableConstraints: [],
    );

    await db.createMigrator().createTable(table);
    await db.close();

    // This should not attempt to generate a parameter (`?`)
    // https://github.com/simolus3/drift/discussions/1936
    verify(executor.executeSql(contains('CHECK("foo" < 3)'), []));
  });

  group('respects schema version', () {
    late MockSession executor;
    late _DefaultDb db;

    setUp(() async {
      executor = MockSession();
      db = _DefaultDb(createConnection(executor));
    });

    tearDown(() {
      return db.close();
    });

    test('in createAll', () async {
      final defaultMigrator = db.createMigrator();
      await defaultMigrator.createAll();
      verifyNever(executor.execute(any));

      final fixedMigrator = Migrator(db, _FakeSchemaVersion(version: 2));
      await fixedMigrator.createAll();
      verify(
        executor.executeSql(
          'CREATE TABLE IF NOT EXISTS "my_table" ("foo" INTEGER NOT NULL);',
          [],
        ),
      );
      verify(executor.executeSql('CREATE VIEW my_view AS SELECT 2', []));
    });

    test('in recreateViews', () async {
      final defaultMigrator = db.createMigrator();
      await defaultMigrator.recreateAllViews();
      verifyNever(executor.execute(any));

      final fixedMigrator = Migrator(db, _FakeSchemaVersion(version: 2));
      await fixedMigrator.recreateAllViews();

      verify(executor.executeSql('CREATE VIEW my_view AS SELECT 2', []));
    });
  });

  group('dialect-specific', () {
    final dialects = [
      ('sqlite', SqliteDialect.new),
      ('postgres', PostgresDialect.new),
    ];

    CustomComponent statements(String base) {
      return CustomComponent(
        'fallback',
        dialectSpecificSql: {
          for (final dialect in KnownSqlDialect.values)
            dialect: '$base $dialect',
        },
      );
    }

    for (final (name, dialect) in dialects) {
      test('with dialect $name', () async {
        final db = TodoDb(createConnection(mockExecutor, dialect: dialect));
        final resolvedDialect = db.dialect;
        final migrator = db.createMigrator();

        await migrator.create(Trigger('a', statements('trigger')));
        await migrator.create(Index('a', statements('index')));
        await migrator.create(OnCreateQuery(statements('@')));

        verify(mockExecutor.executeSql('trigger ${resolvedDialect.known}', []));
        verify(mockExecutor.executeSql('index ${resolvedDialect.known}', []));
        verify(mockExecutor.executeSql('@ ${resolvedDialect.known}', []));
      });
    }
  });
}

final class _FakeSchemaVersion extends VersionedSchema {
  _FakeSchemaVersion({required super.version});

  @override
  Iterable<DatabaseSchemaEntity> get entities => [
    VersionedTable(
      entityName: 'my_table',
      columns: [
        (name) => TableColumn<int>(
          name: 'foo',
          sqlType: BuiltinDriftType.int,
          constraints: () => [ColumnNotNullConstraint()],
        ),
      ],
      tableConstraints: [],
      isStrict: false,
      withoutRowId: false,
    ),
    VersionedView(
      entityName: 'my_view',
      createViewStmt: 'CREATE VIEW my_view AS SELECT $version',
      columns: [],
    ),
  ];
}

final class _DefaultDb extends GeneratedDatabase {
  _DefaultDb(super.executor);

  @override
  DatabaseSchema get schema => DatabaseSchema.empty;

  @override
  int get schemaVersion => 2;
}
