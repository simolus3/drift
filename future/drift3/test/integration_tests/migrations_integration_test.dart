@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:drift3/drift.dart';
import 'package:drift3/internal/versioned_schema.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:drift_sqlite/schema_verifier.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../generated/custom_tables.dart';
import '../generated/todos.dart';
import '../test_utils.dart';

void main() {
  test('change column types', () async {
    // Create todos table with category as text (it's an int? in Dart).
    final executor = DriftConnection(
      dialect: const SqliteDialect(),
      openConnection: () async {
        final db = sqlite3.openInMemory();
        db
          ..execute('''
        CREATE TABLE todos (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          target_date INTEGER NOT NULL,
          category TEXT NOT NULL,
          status TEXT NULL,
          UNIQUE(title, category)
        );
      ''')
          ..execute('CREATE INDEX my_index ON todos (content);')
          ..execute(
            'INSERT INTO todos (title, content, target_date, category) '
            "VALUES ('title', 'content', '2026-03-25', '12')",
          )
          ..execute(
            'CREATE VIEW todo_categories AS SELECT category FROM todos;',
          )
          ..execute('PRAGMA foreign_keys = ON');
        return SqliteConnection(db);
      },
    );

    final db = TodoDb(executor);
    db.migration = MigrationStrategy(
      onCreate: (m) async {
        await m.alterTable(
          TableMigration(
            db.todosTable,
            columnTransformer: {
              db.todosTable.category: db.todosTable.category.cast<int>(),
            },
          ),
        );
      },
    );

    final createStmt = await db
        .customSelect("SELECT sql FROM sqlite_master WHERE name = 'todos'")
        .map((row) => row.read<String>('sql'))
        .getSingle();

    expect(createStmt, contains('"category" INT'));

    final item = await db.select(db.todosTable).getSingle();
    expect(item.category, 12);

    // We enabled foreign keys, so they should still be enabled now.
    final foreignKeysResult = await db
        .customSelect('PRAGMA foreign_keys')
        .getSingle();
    expect(foreignKeysResult.read<bool>('foreign_keys'), isTrue);

    // Similarly, the legacy_alter_table behavior should be disabled.
    final legacyAlterTable = await db
        .customSelect('PRAGMA legacy_alter_table')
        .getSingle();
    expect(legacyAlterTable.read<bool>('legacy_alter_table'), isFalse);
  });

  test('rename columns', () async {
    // Create todos table with category as category_old
    final executor = DriftConnection(
      dialect: const SqliteDialect(),
      openConnection: () async {
        final db = sqlite3.openInMemory();
        db.execute('''
        CREATE TABLE todos (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          target_date INTEGER NOT NULL,
          category_old INTEGER NULL,
          status TEXT NULL
        );
      ''');

        db.execute(
          'INSERT INTO todos (title, content, target_date) '
          "VALUES ('title', 'content', '2026-03-25')",
        );
        return SqliteConnection(db);
      },
    );

    final db = TodoDb(executor);
    db.migration = MigrationStrategy(
      onCreate: (m) async {
        await m.alterTable(
          TableMigration(
            db.todosTable,
            columnTransformer: {
              db.todosTable.category: Expression.custom('category_old'),
            },
          ),
        );
      },
    );

    final createStmt = await db
        .customSelect("SELECT sql FROM sqlite_master WHERE name = 'todos'")
        .map((row) => row.read<String>('sql'))
        .getSingle();

    expect(
      createStmt,
      allOf(contains('"category" INT'), isNot(contains('category_old'))),
    );

    final item = await db.select(db.todosTable).getSingle();
    expect(item.category, isNull);
  });

  test('delete column', () async {
    // Create todos table with an additional column
    final executor = DriftConnection(
      dialect: const SqliteDialect(),
      openConnection: () async {
        final db = sqlite3.openInMemory();
        db.execute('''
        CREATE TABLE todos (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          target_date INTEGER NOT NULL,
          category INTEGER NULL,
          status TEXT NULL,
          additional_column TEXT NULL
        );
      ''');

        db.execute(
          'INSERT INTO todos (title, content, target_date) '
          "VALUES ('title', 'content', '2026-03-25')",
        );
        return SqliteConnection(db);
      },
    );

    final db = TodoDb(executor);
    db.migration = MigrationStrategy(
      onCreate: (m) async {
        await m.alterTable(TableMigration(db.todosTable));
      },
    );

    final createStmt = await db
        .customSelect("SELECT sql FROM sqlite_master WHERE name = 'todos'")
        .map((row) => row.read<String>('sql'))
        .getSingle();

    expect(createStmt, isNot(contains('additional_column')));

    final item = await db.select(db.todosTable).getSingle();
    expect(item.title, 'title');
  });

  test('delete column with dropColumn', () async {
    // Create todos table with an additional column
    final executor = DriftConnection(
      dialect: const SqliteDialect(),
      openConnection: () async {
        final db = sqlite3.openInMemory();
        db.execute('''
        CREATE TABLE todos (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          target_date INTEGER NOT NULL,
          category INTEGER NULL,
          status TEXT NULL,
          additional_column TEXT NULL
        );
      ''');

        db.execute(
          'INSERT INTO todos (title, content, target_date) '
          "VALUES ('title', 'content', '2026-03-25')",
        );
        return SqliteConnection(db);
      },
    );

    final db = TodoDb(executor);
    db.migration = MigrationStrategy(
      onCreate: (m) async {
        await m.dropColumn(db.todosTable, 'additional_column');
      },
    );

    final createStmt = await db
        .customSelect("SELECT sql FROM sqlite_master WHERE name = 'todos'")
        .map((row) => row.read<String>('sql'))
        .getSingle();

    expect(createStmt, isNot(contains('additional_column')));

    final item = await db.select(db.todosTable).getSingle();
    expect(item.title, 'title');
  });

  test('rename tables', () async {
    // Create todos table with old name
    final executor = DriftConnection(
      dialect: const SqliteDialect(),
      openConnection: () async {
        final db = sqlite3.openInMemory();
        final compiler = const SqliteDialect().createCompiler();
        CreateTableStatement(
          $TodosTableTable('todos_old_name'),
        ).compileWith(compiler);

        db.execute(compiler.statement.toStatementInfo().sql);

        db.execute(
          'INSERT INTO todos_old_name (title, content, target_date) '
          "VALUES ('title', 'content', '2026-03-25')",
        );
        return SqliteConnection(db);
      },
    );

    final db = TodoDb(executor);
    db.migration = MigrationStrategy(
      onCreate: (m) async {
        await m.renameTable(db.todosTable, 'todos_old_name');
      },
    );

    // basic check to ensure we can query the table by its new name and that
    // we have all the necessary data.
    final entry = await db.select(db.todosTable).getSingle();
    expect(entry.title, 'title');
  });

  test('add columns with default value', () async {
    final executor = DriftConnection(
      dialect: const SqliteDialect(),
      openConnection: () async {
        final db = sqlite3.openInMemory();
        // Create todos table without content column
        db.execute('''
        CREATE TABLE todos (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          target_date INTEGER NOT NULL,
          status TEXT NULL,
          category INT
        );
      ''');

        db.execute(
          'INSERT INTO todos (title, target_date, category) VALUES '
          "('Title', '2026-03-26', 0)",
        );
        return SqliteConnection(db);
      },
    );

    final db = TodoDb(executor);
    db.migration = MigrationStrategy(
      onCreate: (m) async {
        await db.transaction(() async {
          await m.alterTable(
            TableMigration(
              db.todosTable,
              newColumns: [db.todosTable.content],
              columnTransformer: {
                db.todosTable.content: const Literal<String>('content'),
              },
            ),
          );

          await db.customStatement(
            "DELETE FROM todos WHERE content != 'content';",
          );
        });
      },
    );

    final entry = await db.select(db.todosTable).getSingle();
    expect(entry.content, 'content');
  });

  test('alter table without rowid', () async {
    final executor = DriftConnection(
      dialect: const SqliteDialect(),
      openConnection: () async {
        final db = sqlite3.openInMemory();
        db.execute(
          'CREATE TABLE no_ids (old BLOB NOT NULL PRIMARY KEY) WITHOUT ROWID',
        );
        return SqliteConnection(db);
      },
    );

    final db = CustomTablesDb(executor);
    db.migration = MigrationStrategy(
      onCreate: (m) async {
        await m.alterTable(
          TableMigration(
            db.noIds,
            columnTransformer: {db.noIds.payload: Expression.custom('old')},
            newColumns: [db.noIds.payload],
          ),
        );
      },
    );
    addTearDown(db.close);

    final entry = await db
        .customSelect("SELECT sql FROM sqlite_master WHERE name = 'no_ids'")
        .getSingle();

    expect(entry.read<String>('sql'), contains('WITHOUT ROWID'));
  });

  test('alter table that has a generated column', () async {
    final db = TodoDb(testInMemoryDatabase());
    addTearDown(db.close);

    await db.categories
        .statements(db)
        .insertOne(
          CategoriesCompanion.insert(description: 'My Initial Description'),
        );

    final migrator = db.createMigrator();
    await migrator.drop(db.categoryTodoCountView);
    await migrator.drop(db.todoWithCategoryView);
    await migrator.alterTable(
      TableMigration(
        db.categories,
        columnTransformer: {
          db.categories.description: db.categories.description.lower(),
        },
      ),
    );
    await migrator.recreateAllViews();

    final value = await db.select(db.categories).getSingle();
    expect(value.description, 'my initial description');
  });

  test('can run migration with variable', () async {
    final db = TodoDb(testInMemoryDatabase());
    addTearDown(db.close);

    await db.todosTable
        .statements(db)
        .insertOne(TodosTableCompanion.insert(content: 'my content'));

    final migrator = db.createMigrator();
    await migrator.drop(db.categoryTodoCountView);
    await migrator.drop(db.todoWithCategoryView);
    await migrator.alterTable(
      TableMigration(
        db.todosTable,
        columnTransformer: {
          db.todosTable.content: Variable('old: ') + db.todosTable.content,
        },
      ),
    );
    await migrator.recreateAllViews();

    final value = await db.select(db.todosTable).getSingle();
    expect(value.content, 'old: my content');
  });

  group('exceptions in migrations', () {
    test('do not change the user version', () async {
      late Database nativeDb;
      final db = _TestDatabase(
        DriftConnection(
          dialect: const SqliteDialect(),
          openConnection: () async =>
              SqliteConnection(nativeDb = sqlite3.openInMemory()),
        ),
        1,
        MigrationStrategy(onCreate: (m) => Future.error('do not migrate')),
      );
      addTearDown(db.close);

      await expectLater(db.initialize(), throwsA('do not migrate'));
      expect(nativeDb.userVersion, isZero);
    });

    test(
      'do not change the user version when in a nested transaction',
      () async {
        final nativeDb = sqlite3.openInMemory();
        var db = _TestDatabase(
          DriftConnection(
            dialect: const SqliteDialect(),
            openConnection: () async =>
                SqliteConnection(nativeDb, closeUnderlyingWhenClosed: false),
          ),
          1,
          MigrationStrategy(),
        );
        await db.initialize();
        await db.close();

        db = _TestDatabase(
          DriftConnection(
            dialect: const SqliteDialect(),
            openConnection: () async => SqliteConnection(nativeDb),
          ),
          2,
          MigrationStrategy(
            onCreate: (m) => Future.error('Should not call onCreate'),
            onUpgrade: expectAsync3((m, from, to) {
              expect(from, 1);
              expect(to, 2);

              return db.transaction(() => Future.error('error in transaction'));
            }),
          ),
        );
        addTearDown(db.close);

        await expectLater(db.initialize(), throwsA('error in transaction'));
        expect(nativeDb.userVersion, 1);
      },
    );

    test('can set user version in callback', () async {
      final nativeDb = sqlite3.openInMemory();
      var db = _TestDatabase(
        DriftConnection(
          dialect: const SqliteDialect(),
          openConnection: () async =>
              SqliteConnection(nativeDb, closeUnderlyingWhenClosed: false),
        ),
        1,
        MigrationStrategy(),
      );
      await db.initialize();

      db = _TestDatabase(
        DriftConnection(
          dialect: const SqliteDialect(),
          openConnection: () async => SqliteConnection(nativeDb),
        ),
        10,
        MigrationStrategy(
          onCreate: (m) => Future.error('Should not call onCreate'),
          onUpgrade: expectAsync3((m, from, to) async {
            expect(from, 1);
            expect(to, 10);

            await db.customStatement('CREATE TABLE foo (bar INT);');
            await db.customStatement('pragma user_version = 3');

            await db.transaction(
              () => Future<void>.error('Error after partial migration'),
            );
          }),
        ),
      );
      addTearDown(db.close);

      await expectLater(
        db.initialize(),
        throwsA('Error after partial migration'),
      );
      expect(nativeDb.userVersion, 3);
    });
  });

  group('verifySelf', () {
    test('throws when a schema is not created properly', () {
      final db = TodoDb(testInMemoryDatabase());
      addTearDown(db.close);

      db.migration = MigrationStrategy(
        onCreate: (m) async {
          // Only creating one table, won't be enough
          await m.createTable(db.categories);
        },
        beforeOpen: (details) async {
          await db.validateDatabaseSchema(connection: testInMemoryDatabase());
        },
      );

      expect(
        db.customSelect('SELECT 1;').get(),
        throwsA(isA<SchemaMismatch>()),
      );
    });

    test('does not throw for a matching schema', () {
      final db = TodoDb(testInMemoryDatabase());
      addTearDown(db.close);

      db.migration = MigrationStrategy(
        // use default and correct `onCreate`, validation should work
        beforeOpen: (details) async {
          await db.validateDatabaseSchema(connection: testInMemoryDatabase());
        },
      );

      expect(db.customSelect('SELECT 1;').get(), completes);
    });

    test("can be used on a database before it's opened", () async {
      final db = TodoDb(testInMemoryDatabase());
      addTearDown(db.close);

      expect(
        db.validateDatabaseSchema(connection: testInMemoryDatabase()),
        completes,
      );
    });
  });

  test('custom schema upgrades', () async {
    // I promised this would work in https://github.com/simolus3/drift/discussions/2436,
    // so we better make sure this keeps working.
    final underlying = sqlite3.openInMemory()
      ..execute('pragma user_version = 1;');
    addTearDown(underlying.close);

    const maxSchema = 10;
    final expectedException = Exception('schema upgrade!');

    for (var currentSchema = 1; currentSchema < maxSchema; currentSchema++) {
      final db = TodoDb(
        DriftConnection(
          dialect: const SqliteDialect(),
          openConnection: () async =>
              SqliteConnection(underlying, closeUnderlyingWhenClosed: false),
        ),
      );
      db.schemaVersion = maxSchema;
      db.migration = MigrationStrategy(
        onUpgrade: expectAsync3((m, from, to) async {
          // This upgrade callback does one step and then throws. Opening the
          // database multiple times should run the individual migrations.
          expect(from, currentSchema);
          expect(to, maxSchema);

          await db.customStatement('CREATE TABLE t$from (id INTEGER);');
          await db.customStatement('pragma user_version = ${from + 1}');

          if (from != to - 1) {
            // Simulate a failed upgrade
            throw expectedException;
          }
        }),
      );

      if (currentSchema != maxSchema - 1) {
        // Opening the database should throw this exception
        await expectLater(
          db.customSelect('SELECT 1').get(),
          throwsA(expectedException),
        );
      } else {
        // The last migration should work
        await expectLater(db.customSelect('SELECT 1').get(), completes);
      }
    }
  });

  test('step-by-step migrations saves state halfway', () async {
    final underlying = sqlite3.openInMemory()
      ..execute('pragma user_version = 1;');
    addTearDown(underlying.close);

    final expectedException = Exception('schema upgrade!');

    final db =
        TodoDb(
            DriftConnection(
              dialect: const SqliteDialect(),
              openConnection: () async => SqliteConnection(underlying),
            ),
          )
          ..schemaVersion = 5
          ..migration = MigrationStrategy(
            onUpgrade: VersionedSchema.stepByStepHelper(
              step: (version, database) async {
                await database.customStatement(
                  'CREATE TABLE t$version (id INT);',
                );

                if (version == 3) {
                  throw expectedException;
                }

                return version + 1;
              },
            ),
          );

    await expectLater(
      db.customSelect('SELECT 1').get(),
      throwsA(expectedException),
    );

    expect(underlying.userVersion, 3);
  });

  test('step-by-step migrations throw on downgrades', () async {
    final underlying = sqlite3.openInMemory()..userVersion = 5;
    addTearDown(underlying.close);

    final db =
        TodoDb(
            DriftConnection(
              dialect: const SqliteDialect(),
              openConnection: () async => SqliteConnection(
                underlying,
                closeUnderlyingWhenClosed: false,
              ),
            ),
          )
          ..schemaVersion = 3
          ..migration = MigrationStrategy(
            onUpgrade: VersionedSchema.stepByStepHelper(
              step: (version, database) async {
                return version + 1;
              },
            ),
          );

    await expectLater(db.customSelect('SELECT 1').get(), throwsStateError);
    expect(underlying.userVersion, 5);
  });

  test(
    "alterTable works for databases that can't set legacy alter table",
    () async {
      final interceptor = _NoLegacyAlterTable();
      final db = TodoDb(testInMemoryDatabase().interceptWith(interceptor));
      addTearDown(db.close);

      final user = await db.users
          .statements(db)
          .insertReturning(
            UsersCompanion.insert(
              name: 'test user',
              profilePicture: Uint8List(0),
            ),
          );
      await Migrator(db).alterTable(TableMigration(db.users));
      expect(await db.select(db.users).get(), [user]);
      expect(interceptor.didPreventLegacyAlterTable, isTrue);
    },
  );
}

final class _TestDatabase extends GeneratedDatabase {
  _TestDatabase(super.implementation, this.schemaVersion, this.migration);

  @override
  DatabaseSchema get schema => DatabaseSchema.empty;

  @override
  final int schemaVersion;

  @override
  final MigrationStrategy migration;
}

final class _NoLegacyAlterTable extends QueryInterceptor {
  var didPreventLegacyAlterTable = false;

  @override
  Future<QueryResult> execute(DriftSession session, StatementInfo statement) {
    final sql = statement.sql;
    if (sql.contains('legacy_alter_table') && sql.contains('=')) {
      didPreventLegacyAlterTable = true;
      throw 'not allowed';
    }

    return super.execute(session, statement);
  }
}
