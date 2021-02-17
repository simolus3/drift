import 'package:test/test.dart';
import 'package:moor/moor.dart';

import '../data/tables/todos.dart';
import '../data/utils/expect_generated.dart';

void main() {
  final db = TodoDb();

  final innerExpression = GeneratedTextColumn('name', 'table', true);
  group('values', () {
    test('in expressions are generated', () {
      final isInExpression = innerExpression.isIn(['Max', 'Tobias']);

      expect(isInExpression, generates('name IN (?, ?)', ['Max', 'Tobias']));
    });

    test('not in expressions are generated', () {
      final isNotIn = innerExpression.isNotIn(['Max', 'Tobias']);

      expect(isNotIn, generates('name NOT IN (?, ?)', ['Max', 'Tobias']));
    });
  });

  group('subquery', () {
    test('in expressions are generated', () {
      final isInExpression = innerExpression
          .isInQuery(db.selectOnly(db.users)..addColumns([db.users.name]));

      expect(isInExpression,
          generates('name IN (SELECT users.name AS "users.name" FROM users)'));
    });

    test('not in expressions are generated', () {
      final isInExpression = innerExpression
          .isNotInQuery(db.selectOnly(db.users)..addColumns([db.users.name]));

      expect(
          isInExpression,
          generates(
              'name NOT IN (SELECT users.name AS "users.name" FROM users)'));
    });
  });
}
