import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';
import '../data/utils/expect_generated.dart';

void main() {
  final expression = GeneratedTextColumn('col', 'table', false);
  final db = TodoDb();

  test('generates like expressions', () {
    final ctx = GenerationContext.fromDb(db);
    expression.like('pattern').writeInto(ctx);

    expect(ctx.sql, 'col LIKE ?');
    expect(ctx.boundVariables, ['pattern']);
  });

  test('generates regexp expressions', () {
    expect(
      expression.regexp('fo+'),
      generates('col REGEXP ?', ['fo+']),
    );
  });

  test('generates collate expressions', () {
    final ctx = GenerationContext.fromDb(db);
    expression.collate(Collate.noCase).writeInto(ctx);

    expect(ctx.sql, 'col COLLATE NOCASE');
    expect(ctx.boundVariables, isEmpty);
  });

  test('can use contains', () {
    expect(
        expression.contains('foo bar'), generates('col LIKE ?', ['%foo bar%']));
  });

  test('can use string functions', () {
    expect(expression.upper(), generates('UPPER(col)'));
    expect(expression.lower(), generates('LOWER(col)'));
    expect(expression.length, generates('LENGTH(col)'));
  });
}
