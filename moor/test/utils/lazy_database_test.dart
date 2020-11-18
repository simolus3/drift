//@dart=2.9
import 'package:moor/moor.dart';
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';
import '../data/utils/mocks.dart';

class _LazyQueryUserForTest extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
    // do nothing
    return Future.value();
  }
}

void main() {
  test('lazy database delegates work', () async {
    final inner = MockExecutor();
    final lazy = LazyDatabase(() => inner);

    await lazy.ensureOpen(_LazyQueryUserForTest());
    clearInteractions(inner);

    lazy.beginTransaction();
    await lazy.runBatched(null);
    await lazy.runCustom('custom_stmt');
    await lazy.runDelete('delete_stmt', [1]);
    await lazy.runInsert('insert_stmt', [2]);
    await lazy.runSelect('select_stmt', [3]);
    await lazy.runUpdate('update_stmt', [4]);

    verifyInOrder([
      inner.runBatched(null),
      inner.runCustom('custom_stmt'),
      inner.runDelete('delete_stmt', [1]),
      inner.runInsert('insert_stmt', [2]),
      inner.runSelect('select_stmt', [3]),
      inner.runUpdate('update_stmt', [4]),
    ]);
  });

  test('database is only opened once', () async {
    final inner = MockExecutor();
    var openCount = 0;
    final lazy = LazyDatabase(() {
      openCount++;
      return inner;
    });

    final user = _LazyQueryUserForTest();
    for (var i = 0; i < 10; i++) {
      unawaited(lazy.ensureOpen(user));
    }

    await pumpEventQueue();
    expect(openCount, 1);
  });

  test('opens the inner database with the outer user', () async {
    final inner = MockExecutor();
    final db = TodoDb(LazyDatabase(() => inner));

    // run a statement to make sure the database has been opened
    await db.customSelect('custom_select').get();

    verify(inner.ensureOpen(db));
  });

  test('returns the existing delegate if it was open', () async {
    final inner = MockExecutor();
    final lazy = LazyDatabase(() => inner);
    final user = _LazyQueryUserForTest();

    await lazy.ensureOpen(user);
    await lazy.ensureOpen(user);

    verify(inner.ensureOpen(user));
  });

  test('can close inner executor', () async {
    final inner = MockExecutor();
    final lazy = LazyDatabase(() => inner);
    final user = _LazyQueryUserForTest();

    await lazy.close(); // Close before opening, expect no effect

    await lazy.ensureOpen(user);
    await lazy.close();

    verify(inner.close());
  });
}
