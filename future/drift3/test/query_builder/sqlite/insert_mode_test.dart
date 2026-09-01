import 'dart:typed_data';

import 'package:drift3_preview/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils.dart';
import '../../test_utils/mocks.dart';

void main() {
  late TodoDb db;
  late MockSession session;

  setUp(() async {
    session = MockSession();
    db = TodoDb(createConnection(session));

    // Don't collect CREATE TABLE statements in mock to make debugging easier.
    await db.initialize();
    clearInteractions(session);
  });

  group('batch', () {
    test('insertMode', () async {
      await db.batch((b) {
        b.insertMode(
          .replace,
          db.users,
          UsersCompanion.insert(
            name: 'Test user',
            profilePicture: Uint8List(0),
          ),
        );
      });

      verify(
        session.transactions.executeBatch(
          argThat(
            isA<StatementBatch>().having(
              (e) => e.sql,
              'sql',
              contains(contains('REPLACE INTO')),
            ),
          ),
        ),
      );
    });

    test('insertFromSelectMode', () async {
      await db.batch((b) {
        b.insertFromSelectMode(
          .insertOrIgnore,
          db.users,
          db.selectOnly(db.users),
          columns: {},
        );
      });

      verify(
        session.transactions.executeBatch(
          argThat(
            isA<StatementBatch>().having(
              (e) => e.sql,
              'sql',
              contains(contains('INSERT OR IGNORE INTO')),
            ),
          ),
        ),
      );
    });

    test('insertAllMode', () async {
      await db.batch((b) {
        b.insertAllMode(.insertOrIgnore, db.users, [
          UsersCompanion.insert(
            name: 'Test user',
            profilePicture: Uint8List(0),
          ),
        ]);
      });

      verify(
        session.transactions.executeBatch(
          argThat(
            isA<StatementBatch>().having(
              (e) => e.sql,
              'sql',
              contains(contains('INSERT OR IGNORE INTO')),
            ),
          ),
        ),
      );
    });
  });

  group('extension', () {
    test('insertOneMode', () async {
      await db.categoriesQueries.insertOneMode(
        .insertOrAbort,
        CategoriesCompanion.insert(description: 'desc'),
      );
      verify(session.executeSql(contains('INSERT OR ABORT'), anything));
    });

    test('insertAllMode', () async {
      await db.categoriesQueries.insertAllMode(.insertOrIgnore, [
        CategoriesCompanion.insert(description: 'description'),
      ]);

      verify(
        session.transactions.transactions.executeBatch(
          argThat(
            isA<StatementBatch>().having(
              (e) => e.sql,
              'sql',
              contains(contains('INSERT OR IGNORE INTO')),
            ),
          ),
        ),
      );
    });

    test('insertReturningMode', () async {
      when(session.execute(argThat(anything))).thenAnswer((_) async {
        return queryResult([
          {
            'id': 0,
            'description': 'desc',
            'priority': 1,
            'descriptionInUpperCase': 'DESC',
          },
        ]);
      });

      await db.categoriesQueries.insertReturningMode(
        .insertOrRollback,
        CategoriesCompanion.insert(description: 'desc'),
      );

      verify(session.executeSql(contains('INSERT OR ROLLBACK'), anything));
    });
  });
}
