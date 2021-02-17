import 'package:test/test.dart';
import 'package:moor/moor.dart';

import '../data/tables/todos.dart';

void main() {
  test('exists expressions are generated', () {
    final db = TodoDb();
    final subquery = db.select(db.users)
      ..where((tbl) => tbl.isAwesome.equals(true));
    final existsExpression = existsQuery(subquery);

    final context = GenerationContext.fromDb(db);
    existsExpression.writeInto(context);

    expect(context.sql, 'EXISTS (SELECT * FROM users WHERE is_awesome = ?)');
    expect(context.boundVariables, [1]);
  });

  test('not exists expressions are generated', () {
    final db = TodoDb();
    final isInExpression = notExistsQuery(db.select(db.users));

    final context = GenerationContext.fromDb(db);
    isInExpression.writeInto(context);

    expect(context.sql, 'NOT EXISTS (SELECT * FROM users)');
  });
}
