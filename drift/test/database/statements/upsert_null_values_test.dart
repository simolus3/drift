@TestOn('vm')
library;

import 'package:drift/drift.dart' hide isNull;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

/// Tests for [DriftDatabaseOptions.upsertsWriteNullValues].
///
/// Without the option, the `DO UPDATE SET` clause of an upsert treats `null`
/// values as absent, so a conflicting row keeps whatever value it had before.
/// That makes `INSERT ... ON CONFLICT DO UPDATE` behave differently depending
/// on whether the row already existed, see
/// https://github.com/simolus3/drift/issues/2998.
void main() {
  group('SQL generation', () {
    late TodoDb db;
    late MockExecutor executor;

    setUp(() {
      executor = MockExecutor();
      db = TodoDb(createConnection(executor, MockStreamQueries()));
    });

    /// A full row with `null` in every nullable column.
    const entry = TodoEntry(id: RowId(3), content: 'content');

    group('with the default options', () {
      test('drops null columns from the update clause', () async {
        await db.into(db.todosTable).insertOnConflictUpdate(entry);

        verify(
          executor.runInsert(
            'INSERT INTO "todos" ("id", "content") VALUES (?, ?) '
            'ON CONFLICT("id") DO UPDATE SET "id" = ?, "content" = ?',
            [3, 'content', 3, 'content'],
          ),
        );
      });

      test('drops null columns for an explicit DoUpdate clause', () async {
        await db
            .into(db.todosTable)
            .insert(entry, onConflict: DoUpdate((_) => entry));

        verify(
          executor.runInsert(
            'INSERT INTO "todos" ("id", "content") VALUES (?, ?) '
            'ON CONFLICT("id") DO UPDATE SET "id" = ?, "content" = ?',
            [3, 'content', 3, 'content'],
          ),
        );
      });
    });

    group('with upsertsWriteNullValues', () {
      setUp(() {
        db.options = const DriftDatabaseOptions(upsertsWriteNullValues: true);
      });

      test('writes null columns into the update clause', () async {
        await db.into(db.todosTable).insertOnConflictUpdate(entry);

        verify(
          executor.runInsert(
            'INSERT INTO "todos" ("id", "content") VALUES (?, ?) '
            'ON CONFLICT("id") DO UPDATE SET '
            '"id" = ?, "title" = ?, "content" = ?, '
            '"target_date" = ?, "category" = ?, "status" = ?',
            [3, 'content', 3, null, 'content', null, null, null],
          ),
        );
      });

      test('writes null columns for an explicit DoUpdate clause', () async {
        await db
            .into(db.todosTable)
            .insert(entry, onConflict: DoUpdate((_) => entry));

        verify(
          executor.runInsert(
            'INSERT INTO "todos" ("id", "content") VALUES (?, ?) '
            'ON CONFLICT("id") DO UPDATE SET '
            '"id" = ?, "title" = ?, "content" = ?, '
            '"target_date" = ?, "category" = ?, "status" = ?',
            [3, 'content', 3, null, 'content', null, null, null],
          ),
        );
      });

      test('does not change the INSERT part of the statement', () async {
        await db.into(db.todosTable).insertOnConflictUpdate(entry);

        final sql =
            verify(executor.runInsert(captureAny, any)).captured.single
                as String;
        expect(sql, startsWith('INSERT INTO "todos" ("id", "content")'));
      });

      test('leaves absent companion values out of the update clause', () async {
        // Companions distinguish between `Value.absent()` and `Value(null)`,
        // so they must not be affected by this option at all.
        await db
            .into(db.todosTable)
            .insertOnConflictUpdate(
              const TodosTableCompanion(
                id: Value(RowId(3)),
                content: Value('content'),
                title: Value(null),
              ),
            );

        verify(
          executor.runInsert(
            'INSERT INTO "todos" ("id", "title", "content") '
            'VALUES (?, ?, ?) '
            'ON CONFLICT("id") DO UPDATE SET '
            '"id" = ?, "title" = ?, "content" = ?',
            [3, null, 'content', 3, null, 'content'],
          ),
        );
      });

      test('does not affect DoNothing clauses', () async {
        await db.into(db.todosTable).insert(entry, onConflict: DoNothing());

        verify(
          executor.runInsert(
            'INSERT INTO "todos" ("id", "content") VALUES (?, ?) '
            'ON CONFLICT("id") DO NOTHING',
            [3, 'content'],
          ),
        );
      });
    });
  });

  group('against a real database', () {
    late TodoDb db;

    setUp(() => db = TodoDb(testInMemoryDatabase()));
    tearDown(() => db.close());

    Future<TodoEntry> insertInitialRow() async {
      await db
          .into(db.todosTable)
          .insert(
            TodosTableCompanion.insert(
              content: 'initial content',
              title: const Value('initial title'),
              status: const Value(TodoStatus.open),
            ),
          );
      return db.select(db.todosTable).getSingle();
    }

    test('keeps stale values by default', () async {
      final row = await insertInitialRow();

      // Upsert the same row, but with the nullable columns cleared.
      final cleared = TodoEntry(id: row.id, content: 'new content');
      await db.into(db.todosTable).insertOnConflictUpdate(cleared);

      final updated = await db.select(db.todosTable).getSingle();
      expect(updated.content, 'new content');
      // The bug: the row that comes back does not match the row we upserted.
      expect(updated.title, 'initial title');
      expect(updated.status, TodoStatus.open);
      expect(updated, isNot(cleared));
    });

    test('writes nulls with upsertsWriteNullValues', () async {
      final row = await insertInitialRow();
      db.options = const DriftDatabaseOptions(upsertsWriteNullValues: true);

      final cleared = TodoEntry(id: row.id, content: 'new content');
      await db.into(db.todosTable).insertOnConflictUpdate(cleared);

      final updated = await db.select(db.todosTable).getSingle();
      expect(updated.content, 'new content');
      expect(updated.title, null);
      expect(updated.status, null);
      // The whole point: an upsert now yields the row that was passed in,
      // regardless of whether it inserted or updated.
      expect(updated, cleared);
    });

    test('upserting a new row is unaffected by the option', () async {
      db.options = const DriftDatabaseOptions(upsertsWriteNullValues: true);

      const fresh = TodoEntry(id: RowId(1), content: 'content');
      await db.into(db.todosTable).insertOnConflictUpdate(fresh);

      expect(await db.select(db.todosTable).getSingle(), fresh);
    });
  });
}
