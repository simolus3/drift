// Tests that wouldn't compile with null safety enabled.
//@dart=2.9

import 'package:moor/moor.dart';
import 'package:test/test.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;
  MockStreamQueries streamQueries;

  setUp(() {
    executor = MockExecutor();
    streamQueries = MockStreamQueries();

    final connection = createConnection(executor, streamQueries);
    db = TodoDb.connect(connection);
  });

  test("doesn't allow writing null rows", () {
    expect(
      () {
        return db.into(db.todosTable).insert(null);
      },
      throwsA(const TypeMatcher<InvalidDataException>().having(
          (e) => e.message, 'message', contains('Cannot write null row'))),
    );
  });
}
