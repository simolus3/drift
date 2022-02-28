import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';
import '../data/utils/mocks.dart';

void main() {
  late MockExecutor read, write;
  late MultiExecutor multi;
  late TodoDb db;

  setUp(() {
    read = MockExecutor();
    write = MockExecutor();

    multi = MultiExecutor(read: read, write: write);
    db = TodoDb(multi);
  });

  test('opens delegated executors when opening', () async {
    await multi.ensureOpen(db);

    verify(read.ensureOpen(argThat(isNot(db))));
    verify(write.ensureOpen(db));
  });

  test('runs selects on the reading executor', () async {
    await multi.ensureOpen(db);

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
    await multi.ensureOpen(db);

    await multi.runUpdate('update', []);
    await multi.runInsert('insert', []);
    await multi.runDelete('delete', []);
    await multi.runBatched(BatchedStatements([], []));

    verify(write.runUpdate('update', []));
    verify(write.runInsert('insert', []));
    verify(write.runDelete('delete', []));
    verify(write.runBatched(BatchedStatements([], [])));
  });

  test('runs transactions on the writing executor', () async {
    await multi.ensureOpen(db);

    final transaction = multi.beginTransaction();
    await transaction.ensureOpen(db);
    await transaction.runSelect('select', []);

    verify(write.beginTransaction());
    verify(write.transactions.ensureOpen(any));
    verify(write.transactions.runSelect('select', []));
  });
}
