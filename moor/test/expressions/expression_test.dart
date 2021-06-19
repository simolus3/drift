import 'package:test/test.dart';

import 'package:moor/moor.dart';
import '../data/tables/todos.dart';
import '../data/utils/expect_generated.dart';

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
        generates('(SELECT users.name AS "users.name" FROM users)'));
  });

  test('does not allow subqueries with more than one column', () {
    final db = TodoDb();

    expect(
        () => subqueryExpression<String>(db.select(db.users)),
        throwsA(isArgumentError.having((e) => e.message, 'message',
            contains('Must return exactly one column'))));
  });

  test('does not count columns with useColumns: false', () {
    // Regression test for https://github.com/simolus3/moor/issues/1189
    final db = TodoDb();

    expect(
      subqueryExpression<String>(db.selectOnly(db.users)
        ..addColumns([db.users.name])
        ..join([
          innerJoin(db.categories, db.categories.id.equalsExp(db.users.id),
              useColumns: false)
        ])),
      generates('(SELECT users.name AS "users.name" FROM users '
          'INNER JOIN categories ON categories.id = users.id)'),
    );
  });
}
