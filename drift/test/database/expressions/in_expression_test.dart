import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  final db = TodoDb();

  const innerExpression =
      CustomExpression<String>('name', precedence: Precedence.primary);
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

  group('expressions', () {
    test('in', () {
      final isInExpression = innerExpression.isInExp([
        CustomExpression('a'),
        CustomExpression('b'),
      ]);

      expect(isInExpression, generates('name IN (a, b)'));
    });

    test('not in', () {
      final isNotInExpression = innerExpression.isNotInExp([
        CustomExpression('a'),
        CustomExpression('b'),
      ]);

      expect(isNotInExpression, generates('name NOT IN (a, b)'));
    });
  });

  group('subquery', () {
    test('in expressions are generated', () {
      final isInExpression = innerExpression
          .isInQuery(db.selectOnly(db.users)..addColumns([db.users.name]));

      expect(
          isInExpression,
          generates(
              'name IN (SELECT "users"."name" AS "users.name" FROM "users")'));

      final ctx = stubContext();
      isInExpression.writeInto(ctx);
      expect(ctx.watchedTables, contains(db.users));
    });

    test('not in expressions are generated', () {
      final isInExpression = innerExpression
          .isNotInQuery(db.selectOnly(db.users)..addColumns([db.users.name]));

      expect(
          isInExpression,
          generates(
              'name NOT IN (SELECT "users"."name" AS "users.name" FROM "users")'));
    });

    test('avoids generating empty tuples', () {
      // Some dialects don't support the `x IS IN ()` form, so we should avoid
      // it and replace it with the direct constant (since nothing can be a
      // member of the empty set). sqlite3 seems to do the same thing, as
      // `NULL IN ()` is `0` and not `NULL`.
      expect(innerExpression.isIn([]), generates('FALSE'));
      expect(innerExpression.isNotIn([]), generates('TRUE'));
    });
  });
}
