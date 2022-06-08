@Tags(['integration'])
@TestOn('vm')
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';

void main() {
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
}
