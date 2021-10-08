@TestOn('vm')
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../data/tables/custom_tables.dart';
import '../data/tables/todos.dart';

void main() {
  test('change column types', () async {
    // Create todos table with category as text (it's an int? in Dart).
    final executor = NativeDatabase.memory(setup: (db) {
      db.execute('''
        CREATE TABLE todos (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          target_date INTEGER NOT NULL,
          category TEXT NOT NULL,
          UNIQUE(title, category)
        );
      ''');

      db.execute('CREATE INDEX my_index ON todos (content);');

      db.execute('INSERT INTO todos (title, content, target_date, category) '
          "VALUES ('title', 'content', 0, '12')");

      db.execute('PRAGMA foreign_keys = ON');
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
        .map((row) => row.readString('sql'))
        .getSingle();

    expect(createStmt, contains('category INT'));

    final item = await db.select(db.todosTable).getSingle();
    expect(item.category, 12);

    // We enabled foreign keys, so they should still be enabled now.
    final foreignKeysResult =
        await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(foreignKeysResult.readBool('foreign_keys'), isTrue);
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
          category_old INTEGER NULL
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
        .map((row) => row.readString('sql'))
        .getSingle();

    expect(
      createStmt,
      allOf(contains('category INT'), isNot(contains('category_old'))),
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
        .map((row) => row.readString('sql'))
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

    final entry = await db
        .customSelect("SELECT sql FROM sqlite_master WHERE name = 'no_ids'")
        .getSingle();

    expect(entry.readString('sql'), contains('WITHOUT ROWID'));
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
                () => Future.error('Error after partial migration'));
          }),
        ),
      );
      addTearDown(db.close);

      await expectLater(
          db.doWhenOpened((_) {}), throwsA('Error after partial migration'));
      expect(nativeDb.userVersion, 3);
    });
  });
}

class _TestDatabase extends GeneratedDatabase {
  _TestDatabase(QueryExecutor executor, this.schemaVersion, this.migration)
      : super(const SqlTypeSystem.withDefaults(), executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const Iterable.empty();

  @override
  final int schemaVersion;

  @override
  final MigrationStrategy migration;
}
