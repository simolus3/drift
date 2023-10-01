@TestOn('vm')
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/internal/versioned_schema.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../generated/custom_tables.dart';
import '../generated/todos.dart';
import '../test_utils/database_vm.dart';

void main() {
  preferLocalSqlite3();

  test('change column types', () async {
    // Create todos table with category as text (it's an int? in Dart).
    final executor = NativeDatabase.memory(setup: (db) {
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
        ..execute('INSERT INTO todos (title, content, target_date, category) '
            "VALUES ('title', 'content', 0, '12')")
        ..execute('CREATE VIEW todo_categories AS SELECT category FROM todos;')
        ..execute('PRAGMA foreign_keys = ON');
    });

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
    final foreignKeysResult =
        await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(foreignKeysResult.read<bool>('foreign_keys'), isTrue);

    // Similarly, the legacy_alter_table behavior should be disabled.
    final legacyAlterTable =
        await db.customSelect('PRAGMA legacy_alter_table').getSingle();
    expect(legacyAlterTable.read<bool>('legacy_alter_table'), isFalse);
  });

  test('rename columns', () async {
    // Create todos table with category as category_old
    final executor = NativeDatabase.memory(setup: (db) {
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

      db.execute('INSERT INTO todos (title, content, target_date) '
          "VALUES ('title', 'content', 0)");
    });

    final db = TodoDb(executor);
    db.migration = MigrationStrategy(
      onCreate: (m) async {
        await m.alterTable(
          TableMigration(
            db.todosTable,
            columnTransformer: {
              db.todosTable.category: const CustomExpression('category_old'),
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
    final executor = NativeDatabase.memory(setup: (db) {
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

      db.execute('INSERT INTO todos (title, content, target_date) '
          "VALUES ('title', 'content', 0)");
    });

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

    expect(
      createStmt,
      isNot(contains('additional_column')),
    );

    final item = await db.select(db.todosTable).getSingle();
    expect(item.title, 'title');
  });

  test('rename tables', () async {
    // Create todos table with old name
    final executor = NativeDatabase.memory(setup: (db) {
      db.execute('''
        CREATE TABLE todos_old_name (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          target_date INTEGER NOT NULL,
          category INTEGER NULL
        );
      ''');

      db.execute('INSERT INTO todos_old_name (title, content, target_date) '
          "VALUES ('title', 'content', 0)");
    });

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
    final executor = NativeDatabase.memory(setup: (db) {
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

      db.execute('INSERT INTO todos (title, target_date, category) VALUES '
          "('Title', 0, 0)");
    });

    final db = TodoDb(executor);
    db.migration = MigrationStrategy(
      onCreate: (m) async {
        await db.transaction(() async {
          await m.alterTable(
            TableMigration(
              db.todosTable,
              newColumns: [db.todosTable.content],
              columnTransformer: {
                db.todosTable.content: const Constant<String>('content'),
              },
            ),
          );

          await db
              .customStatement("DELETE FROM todos WHERE content != 'content';");
        });
      },
    );

    final entry = await db.select(db.todosTable).getSingle();
    expect(entry.content, 'content');
  });

  test('alter table without rowid', () async {
    final executor = NativeDatabase.memory(setup: (db) {
      db.execute(
          'CREATE TABLE no_ids (old BLOB NOT NULL PRIMARY KEY) WITHOUT ROWID');
    });

    final db = CustomTablesDb(executor);
    db.migration = MigrationStrategy(
      onCreate: (m) async {
        await m.alterTable(TableMigration(
          db.noIds,
          columnTransformer: {
            db.noIds.payload: const CustomExpression('old'),
          },
          newColumns: [db.noIds.payload],
        ));
      },
    );
    addTearDown(db.close);

    final entry = await db
        .customSelect("SELECT sql FROM sqlite_master WHERE name = 'no_ids'")
        .getSingle();

    expect(entry.read<String>('sql'), contains('WITHOUT ROWID'));
  });

  test('alter table that has a generated column', () async {
    final db = TodoDb(NativeDatabase.memory());
    addTearDown(db.close);

    await db.categories.insertOne(
        CategoriesCompanion.insert(description: 'My Initial Description'));

    final migrator = db.createMigrator();
    await migrator.drop(db.categoryTodoCountView);
    await migrator.drop(db.todoWithCategoryView);
    await migrator.alterTable(TableMigration(
      db.categories,
      columnTransformer: {
        db.categories.description: db.categories.description.lower(),
      },
    ));
    await migrator.recreateAllViews();

    final value = await db.categories.select().getSingle();
    expect(value.description, 'my initial description');
  });

  test('can run migration with variable', () async {
    final db = TodoDb(NativeDatabase.memory());
    addTearDown(db.close);

    await db.todosTable
        .insertOne(TodosTableCompanion.insert(content: 'my content'));

    final migrator = db.createMigrator();
    await migrator.drop(db.categoryTodoCountView);
    await migrator.drop(db.todoWithCategoryView);
    await migrator.alterTable(TableMigration(
      db.todosTable,
      columnTransformer: {
        db.todosTable.content: Variable('old: ') + db.todosTable.content,
      },
    ));
    await migrator.recreateAllViews();

    final value = await db.todosTable.select().getSingle();
    expect(value.content, 'old: my content');
  });

  group('exceptions in migrations', () {
    test('do not change the user version', () async {
      final nativeDb = sqlite3.openInMemory();
      final db = _TestDatabase(
        NativeDatabase.opened(nativeDb),
        1,
        MigrationStrategy(onCreate: (m) => Future.error('do not migrate')),
      );
      addTearDown(db.close);

      await expectLater(db.doWhenOpened((_) {}), throwsA('do not migrate'));
      expect(nativeDb.userVersion, isZero);
    });

    test('do not change the user version when in a nested transaction',
        () async {
      final nativeDb = sqlite3.openInMemory();
      var db = _TestDatabase(
        NativeDatabase.opened(nativeDb, closeUnderlyingOnClose: false),
        1,
        MigrationStrategy(),
      );
      await db.doWhenOpened((e) {});
      await db.close();

      db = _TestDatabase(
        NativeDatabase.opened(nativeDb),
        2,
        MigrationStrategy(
          onCreate: (m) => Future.error('Should not call onCreate'),
          onUpgrade: expectAsync3(
            (m, from, to) {
              expect(from, 1);
              expect(to, 2);

              return db.transaction(() => Future.error('error in transaction'));
            },
          ),
        ),
      );
      addTearDown(db.close);

      await expectLater(
          db.doWhenOpened((_) {}), throwsA('error in transaction'));
      expect(nativeDb.userVersion, 1);
    });

    test('can set user version in callback', () async {
      final nativeDb = sqlite3.openInMemory();
      var db = _TestDatabase(
          NativeDatabase.opened(nativeDb, closeUnderlyingOnClose: false),
          1,
          MigrationStrategy());
      await db.doWhenOpened((e) {});

      db = _TestDatabase(
        NativeDatabase.opened(nativeDb),
        10,
        MigrationStrategy(
          onCreate: (m) => Future.error('Should not call onCreate'),
          onUpgrade: expectAsync3((m, from, to) async {
            expect(from, 1);
            expect(to, 10);

            await db.customStatement('CREATE TABLE foo (bar INT);');
            await db.customStatement('pragma user_version = 3');

            await db.transaction(
                () => Future<void>.error('Error after partial migration'));
          }),
        ),
      );
      addTearDown(db.close);

      await expectLater(
          db.doWhenOpened((_) {}), throwsA('Error after partial migration'));
      expect(nativeDb.userVersion, 3);
    });
  });

  group('verifySelf', () {
    test('throws when a schema is not created properly', () {
      final executor = NativeDatabase.memory();
      final db = TodoDb(executor);
      addTearDown(db.close);

      db.migration = MigrationStrategy(
        onCreate: (m) async {
          // Only creating one table, won't be enough
          await m.createTable(db.categories);
        },
        beforeOpen: (details) async {
          await db.validateDatabaseSchema();
        },
      );

      expect(
          db.customSelect('SELECT 1;').get(), throwsA(isA<SchemaMismatch>()));
    });

    test('does not throw for a matching schema', () {
      final executor = NativeDatabase.memory();
      final db = TodoDb(executor);
      addTearDown(db.close);

      db.migration = MigrationStrategy(
        // use default and correct `onCreate`, validation should work
        beforeOpen: (details) async {
          await db.validateDatabaseSchema();
        },
      );

      expect(db.customSelect('SELECT 1;').get(), completes);
    });

    test("can be used on a database before it's opened", () async {
      final executor = NativeDatabase.memory();
      final db = TodoDb(executor);
      addTearDown(db.close);

      expect(db.validateDatabaseSchema(), completes);
    });
  });

  test('custom schema upgrades', () async {
    // I promised this would work in https://github.com/simolus3/drift/discussions/2436,
    // so we better make sure this keeps working.
    final underlying = sqlite3.openInMemory()
      ..execute('pragma user_version = 1;');
    addTearDown(underlying.dispose);

    const maxSchema = 10;
    final expectedException = Exception('schema upgrade!');

    for (var currentSchema = 1; currentSchema < maxSchema; currentSchema++) {
      final db = TodoDb(NativeDatabase.opened(underlying));
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
            db.customSelect('SELECT 1').get(), throwsA(expectedException));
      } else {
        // The last migration should work
        await expectLater(db.customSelect('SELECT 1').get(), completes);
      }
    }
  });

  test('step-by-step migrations saves state halfway', () async {
    final underlying = sqlite3.openInMemory()
      ..execute('pragma user_version = 1;');
    addTearDown(underlying.dispose);

    final expectedException = Exception('schema upgrade!');

    final db = TodoDb(NativeDatabase.opened(underlying))
      ..schemaVersion = 5
      ..migration =
          MigrationStrategy(onUpgrade: VersionedSchema.stepByStepHelper(
        step: (version, database) async {
          await database.customStatement('CREATE TABLE t$version (id INT);');

          if (version == 3) {
            throw expectedException;
          }

          return version + 1;
        },
      ));

    await expectLater(
      db.customSelect('SELECT 1').get(),
      throwsA(expectedException),
    );

    expect(underlying.userVersion, 3);
  });
}

class _TestDatabase extends GeneratedDatabase {
  _TestDatabase(QueryExecutor executor, this.schemaVersion, this.migration)
      : super(executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const Iterable.empty();

  @override
  final int schemaVersion;

  @override
  final MigrationStrategy migration;
}
