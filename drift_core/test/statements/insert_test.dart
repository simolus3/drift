import 'package:drift_core/drift_core.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  test('insert values', () {
    expect(
      InsertStatement(
          into: Users(),
          source: InsertValues([
            [sqlVar(3), sqlVar('test')]
          ])),
      generates('INSERT INTO users VALUES (?,?)', [3, 'test']),
    );
  });

  test('insert default values', () {
    expect(
      InsertStatement(into: Users(), source: const DefaultValues()),
      generates('INSERT INTO users DEFAULT VALUES'),
    );
  });

  test('insert from select', () {
    final users = Users();
    expect(
      InsertStatement(
        into: users,
        columns: [users.id],
        source: SelectStatement([users.id()])..from(users),
      ),
      generates('INSERT INTO users (id) SELECT id c0 FROM users'),
    );
  });
}
