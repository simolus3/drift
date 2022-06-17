import 'package:drift/drift.dart';
import 'package:test/test.dart';

import '../../generated/todos.dart';
import '../../test_utils/test_utils.dart';

void main() {
  test('exists expressions are generated', () {
    final db = TodoDb();
    final subquery = db.select(db.users)
      ..where((tbl) => tbl.isAwesome.equals(true));
    final existsExpression = existsQuery(subquery);

    expect(
      existsExpression,
      generates('EXISTS (SELECT * FROM users WHERE users.is_awesome = ?)', [1]),
    );
  });

  test('not exists expressions are generated', () {
    final db = TodoDb();
    final notExistsExpression = notExistsQuery(db.select(db.users));

    expect(
      notExistsExpression,
      generates('NOT EXISTS (SELECT * FROM users)'),
    );
  });
}
