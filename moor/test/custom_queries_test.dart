import 'package:test_api/test_api.dart';

import 'data/tables/todos.dart';
import 'data/utils/mocks.dart';

void main() {
  TodoDb db;
  MockExecutor executor;

  setUp(() {
    executor = MockExecutor();
    db = TodoDb(executor);
  });

  group('compiled custom queries', () {
    // defined query: SELECT * FROM todos WHERE title = ?2 OR id IN ? OR title = ?1
    test('work with arrays', () async {
      await db.withIn('one', 'two', [1, 2, 3]);

      verify(
        executor.runSelect(
          'SELECT * FROM todos WHERE title = ?2 OR id IN (?3, ?4, ?5) OR title = ?1',
          ['one', 'two', 1, 2, 3],
        ),
      );
    });
  });
}
