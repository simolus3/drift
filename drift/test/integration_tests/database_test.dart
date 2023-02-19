@Tags(['integration'])
@TestOn('vm')
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/database_vm.dart';

void main() {
  preferLocalSqlite3();

  test('transaction handles BEGIN throwing', () async {
    final rawDb = sqlite3.open('file:transaction_test?mode=memory&cache=shared',
        uri: true);
    final driftDb = TodoDb(NativeDatabase.opened(sqlite3
        .open('file:transaction_test?mode=memory&cache=shared', uri: true)));
    addTearDown(driftDb.close);
    addTearDown(rawDb.dispose);

    await driftDb
        .into(driftDb.categories)
        .insert(CategoriesCompanion.insert(description: 'description'));

    rawDb.execute('BEGIN EXCLUSIVE');

    await expectLater(
      driftDb.transaction(() {
        return driftDb.select(driftDb.categories).get();
      }),
      throwsA(
        isA<CouldNotRollBackException>().having(
          (e) => e.cause,
          'cause',
          isA<SqliteException>().having((e) => e.causingStatement,
              'causingStatement', 'BEGIN TRANSACTION'),
        ),
      ),
    );

    rawDb.execute('ROLLBACK');

    // Make sure this doesn't block the database
    await expectLater(
        driftDb.select(driftDb.categories).get(), completion(hasLength(1)));
  });

  group('nested transactions', () {
    test(
      'outer transaction does not see inner writes after rollback',
      () async {
        final db = TodoDb(NativeDatabase.memory());

        await db.transaction(() async {
          await db
              .into(db.categories)
              .insert(CategoriesCompanion.insert(description: 'outer'));

          try {
            await db.transaction(() async {
              await db
                  .into(db.categories)
                  .insert(CategoriesCompanion.insert(description: 'inner'));

              expect(await db.select(db.categories).get(), hasLength(2));
              throw Exception('rollback inner');
            });
          } on Exception {
            // Expected rollback, let's continue
          }

          final categories = await db.select(db.categories).get();
          expect(categories, hasLength(1));
          expect(categories.single.description, 'outer');
        });
      },
    );

    test('inner writes are visible after completion', () async {
      final db = TodoDb(NativeDatabase.memory());

      await db.transaction(() async {
        await db
            .into(db.categories)
            .insert(CategoriesCompanion.insert(description: 'outer'));

        await db.transaction(() async {
          await db
              .into(db.categories)
              .insert(CategoriesCompanion.insert(description: 'inner'));
        });

        expect(await db.select(db.categories).get(), hasLength(2));
      });
    });
  });

  test('concurrent batches cause no problems', () async {
    // https://github.com/simolus3/drift/issues/1882#issuecomment-1312756672
    final db = TodoDb(NativeDatabase.memory());

    db.batch((batch) => batch.insert(
        db.categories, CategoriesCompanion.insert(description: 'a')));
    db.batch((batch) => batch.insert(
        db.categories, CategoriesCompanion.insert(description: 'b')));

    await db.customSelect('Select 1').get();
    await db.close();
  });

  test('rolling back after exception with batch in transaction', () async {
    final db = TodoDb(NativeDatabase.memory());
    addTearDown(db.close);

    const expectedException = 'error';

    expectLater(() async {
      await db.transaction(() async {
        await db.batch((b) {
          b.insert(
              db.todosTable, TodosTableCompanion.insert(content: 'my content'));
        });

        throw expectedException;
      });
    }, throwsA(expectedException));

    expect(await db.todosTable.all().get(), isEmpty);
  });
}
