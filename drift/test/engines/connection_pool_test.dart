import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

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

  test('runs selects on reads executor does not block', () async {
    read = MockExecutor();
    final secondRead = MockExecutor();
    write = MockExecutor();

    multi = MultiExecutor.withReadPool(reads: [read, secondRead], write: write);
    db = TodoDb(multi);

    await multi.ensureOpen(db);

    when(read.runSelect(any, any)).thenAnswer((_) {
      return Future.delayed(
          const Duration(milliseconds: 10),
          () => [
                {'foo': 'bar'}
              ]);
    });

    when(secondRead.runSelect(any, any)).thenAnswer((_) async {
      return [
        {'bar': 'foo'}
      ];
    });

    final firstFuture = multi.runSelect('statement', [1]);
    final secondFuture = multi.runSelect('statement', [2]);

    final fasterResult = await Future.any([firstFuture, secondFuture]);
    final firstResult = await firstFuture;
    final secondResult = await secondFuture;

    assert(fasterResult == secondResult);

    verify(read.runSelect('statement', [1]));
    verifyNever(write.runSelect(any, any));
    expect(firstResult, [
      {'foo': 'bar'}
    ]);

    verify(secondRead.runSelect('statement', [2]));
    verifyNever(write.runSelect(any, any));
    expect(secondResult, [
      {'bar': 'foo'}
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
