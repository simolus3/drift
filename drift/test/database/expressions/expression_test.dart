import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../generated/custom_tables.dart';
import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

class _UnknownExpr extends Expression {
  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('???');
  }
}

void main() {
  test('precedence ordering', () {
    expect(Precedence.plusMinus < Precedence.mulDivide, isTrue);
    expect(Precedence.unary <= Precedence.unary, isTrue);
    expect(Precedence.postfix >= Precedence.bitwise, isTrue);
    expect(Precedence.postfix > Precedence.primary, isFalse);
  });

  test('puts parentheses around expressions with unknown precedence', () {
    final expr = _UnknownExpr().equalsExp(_UnknownExpr());
    expect(expr, generates('(???) = (???)'));
  });

  test('generates parentheses for OR in AND', () {
    final c = CustomExpression<String>('c', precedence: Precedence.primary);
    final expr =
        (c.equals('A') | c.equals('B')) & (c.equals('C') | c.equals(''));
    expect(
        expr,
        generates(
            '(c = ? OR c = ?) AND (c = ? OR c = ?)', ['A', 'B', 'C', '']));
  });

  test('generates cast expressions', () {
    const expr = CustomExpression<int>('c');

    expect(expr.cast<String>(), generates('CAST(c AS TEXT)'));
    expect(expr.cast<int>(), generates('CAST(c AS INTEGER)'));
    expect(expr.cast<bool>(), generates('CAST(c AS INTEGER)'));
    expect(expr.cast<DateTime>(), generates('CAST(c AS INTEGER)'));
    expect(expr.cast<double>(), generates('CAST(c AS REAL)'));
    expect(expr.cast<Uint8List>(), generates('CAST(c AS BLOB)'));
  });

  test('generates subqueries', () {
    final db = TodoDb();

    expect(
        subqueryExpression<String>(
            db.selectOnly(db.users)..addColumns([db.users.name])),
        generates('(SELECT "users"."name" AS "users.name" FROM "users")'));
  });

  test('does not allow subqueries with more than one column', () {
    final db = TodoDb();

    expect(
        () => subqueryExpression<String>(db.select(db.users)),
        throwsA(isArgumentError.having((e) => e.message, 'message',
            contains('Must return exactly one column'))));
  });

  test('does not count columns with useColumns: false', () {
    // Regression test for https://github.com/simolus3/drift/issues/1189
    final db = TodoDb();

    expect(
      subqueryExpression<String>(db.selectOnly(db.users)
        ..addColumns([db.users.name])
        ..join([
          innerJoin(db.categories, db.categories.id.equalsExp(db.users.id),
              useColumns: false)
        ])),
      generates('(SELECT "users"."name" AS "users.name" FROM "users" '
          'INNER JOIN "categories" ON "categories"."id" = "users"."id")'),
    );
  });

  group('rowId', () {
    test('cannot be used on virtual tables', () {
      final custom = CustomTablesDb(MockExecutor());
      expect(() => custom.email.rowId, throwsArgumentError);
    });

    test('cannot be used on tables WITHOUT ROWID', () {
      final custom = CustomTablesDb(MockExecutor());
      expect(() => custom.noIds.rowId, throwsArgumentError);
    });

    test('generates a rowid expression', () {
      expect(TodoDb().categories.rowId, generates('"_rowid_"'));
    });

    test('generates an aliased rowid expression when needed', () async {
      final executor = MockExecutor();
      final db = TodoDb(executor);
      addTearDown(db.close);

      final query = db
          .select(db.users)
          .join([innerJoin(db.categories, db.categories.rowId.equals(3))]);
      await query.get();

      verify(executor
          .runSelect(argThat(contains('ON "categories"."_rowid_" = ?')), [3]));
    });
  });

  test('equals', () {
    const a = CustomExpression<int>('a', precedence: Precedence.primary);
    const b = CustomExpression<int>('b', precedence: Precedence.primary);

    expect(a.equals(3), generates('a = ?', [3]));
    expect(a.equalsNullable(3), generates('a = ?', [3]));
    expect(a.equalsNullable(null), generates('a IS NULL'));
    expect(a.equalsExp(b), generates('a = b'));
  });

  test('is', () {
    const a = CustomExpression<int>('a', precedence: Precedence.primary);
    const b = CustomExpression<int>('b', precedence: Precedence.primary);

    expect(a.isValue(3), generates('a IS ?', [3]));
    expect(a.isNotValue(3), generates('a IS NOT ?', [3]));

    expect(a.isExp(b), generates('a IS b'));
    expect(b.isNotExp(a), generates('b IS NOT a'));
  });

  test('Expression.and', () {
    expect(
      Expression.and([
        for (var i = 0; i < 5; i++)
          CustomExpression<bool>('e$i', precedence: Precedence.primary)
      ]),
      generates('e0 AND e1 AND e2 AND e3 AND e4'),
    );

    expect(Expression.and(const []), generates('1'));
    expect(Expression.and(const [], ifEmpty: const Constant(false)),
        generates('0'));
  });

  test('Expression.or', () {
    expect(
      Expression.or([
        for (var i = 0; i < 5; i++)
          CustomExpression<bool>('e$i', precedence: Precedence.primary)
      ]),
      generates('e0 OR e1 OR e2 OR e3 OR e4'),
    );

    expect(Expression.or(const []), generates('0'));
    expect(
        Expression.or(const [], ifEmpty: const Constant(true)), generates('1'));
  });

  test('and and or', () {
    expect(
      Expression.and([
        Expression.or([
          const CustomExpression<bool>('a', precedence: Precedence.primary),
          const CustomExpression<bool>('b', precedence: Precedence.primary),
        ]),
        Expression.and([
          const CustomExpression<bool>('c', precedence: Precedence.primary),
          const CustomExpression<bool>('d', precedence: Precedence.primary),
        ]),
      ]),
      generates('(a OR b) AND c AND d'),
    );
  });

  test('dialect-specific custom expression', () {
    final expr = CustomExpression.dialectSpecific({
      SqlDialect.mariadb: 'mariadb',
      SqlDialect.postgres: 'pg',
      SqlDialect.sqlite: 'default',
    });

    expect(expr, generatesWithOptions('mariadb', dialect: SqlDialect.mariadb));
    expect(expr, generatesWithOptions('pg', dialect: SqlDialect.postgres));
    expect(expr, generatesWithOptions('default', dialect: SqlDialect.sqlite));
  });
}
