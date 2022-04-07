import 'package:drift_core/drift_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  final users = Users();

  test('creates simple select statements', () {
    expect(DeleteStatement(users)..where(users.id().eq(sqlVar(3))),
        generates('DELETE FROM users WHERE id = ?;', [3]));
  });
}
