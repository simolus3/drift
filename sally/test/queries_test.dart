import 'package:sally/sally.dart';
import 'package:test_api/test_api.dart';
import 'package:mockito/mockito.dart';

import 'generated_tables.dart';

class MockExecutor extends Mock implements QueryExecutor {}

void main() {
  TestDatabase db;
  MockExecutor executor;

  setUp(() {
    executor = MockExecutor();
    db = TestDatabase(executor);

    when(executor.runSelect(any, any)).thenAnswer((_) => Future.value([]));
  });

  group('Generates SELECT statements', () {
    test('generates simple statements', () {
      db.select(db.users).get();
      verify(executor.runSelect('SELECT * FROM users;', argThat(isEmpty)));
    });

    test('generates limit statements', () {
      (db.select(db.users)..limit(10)).get();
      verify(executor.runSelect(
          'SELECT * FROM users LIMIT 10;', argThat(isEmpty)));
    });

    test('generates like expressions', () {
      (db.select(db.users)..where((u) => u.name.like('Dash%'))).get();
      verify(executor
          .runSelect('SELECT * FROM users WHERE name LIKE ?;', ['Dash%']));
    });

    test('generates complex predicates', () {
      (db.select(db.users)
            ..where((u) =>
                and(not(u.name.equals('Dash')), (u.id.isBiggerThan(12)))))
          .get();

      verify(executor.runSelect(
          'SELECT * FROM users WHERE (NOT name = ?) AND (id > ?);',
          ['Dash', 12]));
    });

    test('generates expressions from boolean columns', () {
      (db.select(db.users)..where((u) => u.isAwesome)).get();

      verify(executor.runSelect(
          'SELECT * FROM users WHERE (is_awesome = 1);', argThat(isEmpty)));
    });
  });

  group('Generates DELETE statements', () {
    test('without any constraints', () {
      db.delete(db.users).go();

      verify(executor.runDelete('DELETE FROM users;', argThat(isEmpty)));
    });

    test('for complex components', () {
      (db.delete(db.users)
            ..where((u) => or(not(u.isAwesome), u.id.isSmallerThan(100)))
            ..limit(10, offset: 100))
          .go();

      verify(executor.runDelete(
          'DELETE FROM users WHERE (NOT (is_awesome = 1)) OR (id < ?) LIMIT 10, 100;',
          [100]));
    });
  });
}
