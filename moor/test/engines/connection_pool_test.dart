import 'package:moor/moor.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';
import '../data/utils/mocks.dart';

void main() {
  MockExecutor read, write;
  MultiExecutor multi;
  TodoDb db;

  setUp(() {
    read = MockExecutor();
    write = MockExecutor();

    multi = MultiExecutor(read: read, write: write);
    db = TodoDb(multi);
  });

  test('opens delegated executors when opening', () async {
    await multi.ensureOpen();

    verify(write.databaseInfo = db);
    verify(read.databaseInfo = any);

    verify(read.ensureOpen());
    verify(write.ensureOpen());
  });

  test('runs selects on the reading executor', () async {
    await multi.ensureOpen();

    when(read.runSelect(any, any)).thenAnswer((_) async {
      return [
        {'foo': 'bar'}
      ];
    });

    final result = await multi.runSelect('statement', [1, 2]);

    verify(read.runSelect('statement', [1, 2]));
    verifyNever(write.runSelect(any, any));

    expect(result, [
      {'foo': 'bar'}
    ]);
  });

  test('runs updates on the writing executor', () async {
    await multi.ensureOpen();

    await multi.runUpdate('update', []);
    await multi.runInsert('insert', []);
    await multi.runDelete('delete', []);
    await multi.runBatched([]);

    verify(write.runUpdate('update', []));
    verify(write.runInsert('insert', []));
    verify(write.runDelete('delete', []));
    verify(write.runBatched([]));
  });

  test('runs transactions on the writing executor', () async {
    await multi.ensureOpen();

    final transation = multi.beginTransaction();
    await transation.doWhenOpened((e) async {
      await e.runSelect('select', []);
    });

    verify(write.beginTransaction());
    verify(write.transactions.doWhenOpened(any));
    verify(write.transactions.runSelect('select', []));
  });
}
