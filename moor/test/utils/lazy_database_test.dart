import 'package:moor/moor.dart';
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';
import '../data/utils/mocks.dart';

void main() {
  test('lazy database delegates work', () async {
    final inner = MockExecutor();
    final lazy = LazyDatabase(() => inner);

    await lazy.ensureOpen();
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

    for (var i = 0; i < 10; i++) {
      unawaited(lazy.ensureOpen());
    }

    await pumpEventQueue();
    expect(openCount, 1);
  });

  test('sets generated database property', () async {
    final inner = MockExecutor();
    final db = TodoDb(LazyDatabase(() => inner));

    // run a statement to make sure the database has been opened
    await db.customSelectQuery('custom_select').get();

    verify(inner.databaseInfo = db);
  });
}
