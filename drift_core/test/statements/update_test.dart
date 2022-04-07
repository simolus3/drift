import 'package:drift_core/drift_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  final users = Users();

  test('creates simple select statements', () {
    expect(
        UpdateStatement(users, {users.username: sqlVar('new name')})
          ..where(users.id().eq(sqlVar(3))),
        generates('UPDATE users SET name = ? WHERE id = ?;', ['new name', 3]));
  });
}
