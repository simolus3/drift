import 'package:drift_core/drift_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  final users = Users();

  test('creates simple select statements', () {
    expect(SelectStatement([users.id(), users.username()])..from(users),
        generates('SELECT id,name FROM users;'));
  });
}
