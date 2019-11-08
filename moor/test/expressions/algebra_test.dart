import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';

void main() {
  final i1 = GeneratedIntColumn('i1', 'tbl', true);
  final i2 = GeneratedIntColumn('i2', 'tbl', true);
  final s1 = GeneratedTextColumn('s1', 'tbl', true);
  final s2 = GeneratedTextColumn('s2', 'tbl', true);

  test('arithmetic test', () {
    _expectSql(i1 + i2 * i1, '(i1) + ((i2) * (i1))');
  });

  test('string concatenation', () {
    _expectSql(s1 + s2, '(s1) || (s2)');
  });
}

void _expectSql(Expression e, String expected) {
  final ctx = GenerationContext.fromDb(TodoDb(null));
  e.writeInto(ctx);

  expect(ctx.sql, expected);
}
