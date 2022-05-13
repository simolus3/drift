import 'package:drift_core/dialect/sqlite3.dart' as sql;
import 'package:drift_core/drift_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  final users = Users();

  test('creates simple select statements', () {
    expect(SelectStatement([users.id(), users.username()])..from(users),
        generates('SELECT id c0,name c1 FROM users;'));
  });

  test('provides mapping to generated column names', () {
    final stmt =
        SelectStatement([users.id(), users.username(), users.username().upper])
          ..from(users);
    final context = GenerationContext(sql.dialect);
    final result = stmt.writeInto(context);

    expect(context.sql, 'SELECT id c0,name c1,UPPER(name) c2 FROM users;');
    expect(result.columnNameInTable(users.id), 'c0');
    expect(result.columnNameInTable(users.username), 'c1');
    expect(result.columnName(users.username().upper), 'c2');
  });

  test('distinct select', () {
    expect(
        SelectStatement([users.id(), users.username()], distinct: true)
          ..from(users),
        generates('SELECT DISTINCT id c0,name c1 FROM users;'));
  });
}
