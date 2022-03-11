import 'package:drift/drift.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../data/tables/todos.dart';
import '../data/utils/mocks.dart';

void main() {
  late List<MockExecutor> reads;
  late MockExecutor write;
  late MultiExecutor multi;
  late TodoDb db;

  setUp(() {
    reads = [MockExecutor(), MockExecutor()];
    write = MockExecutor();

    multi = MultiExecutor(reads: reads, write: write);
    db = TodoDb(multi);
  });

  test('opens delegated executors when opening', () async {
    await multi.ensureOpen(db);

    for (final read in reads) {
      verify(read.ensureOpen(argThat(isNot(db))));
    }
    verify(write.ensureOpen(db));
  });

  test('runs selects on the reading executor', () async {
    await multi.ensureOpen(db);

    // Two quick queries
    for (final read in reads) {
      when(read.runSelect(any, any)).thenAnswer((_) async => [
            {'foo': 'bar'}
          ]);
    }

    final result = await multi.runSelect('statement', [1, 2]);

    verify(reads[0].runSelect('statement', [1, 2]));
    verifyNever(reads[1].runSelect('statement', [1, 2]));
    verifyNever(write.runSelect(any, any));

    expect(result, [
      {'foo': 'bar'}
    ]);

    // idle executors sort
    reads = [reads[1], reads[0]];
    // first slower query
    when(reads[0].runSelect(any, any)).thenAnswer(
      (_) => Future.delayed(
          const Duration(milliseconds: 4),
          () => [
                {'bar': 'foo'}
              ]),
    );

    final first = multi.runSelect('statement', [2, 1]);
    final second = multi.runSelect('statement', [1, 2]);

    final results = await Future.wait([first, second]);

    verify(reads[0].runSelect('statement', [2, 1]));
    verify(reads[1].runSelect('statement', [1, 2]));
    verifyNever(write.runSelect(any, any));

    expect(results, [
      [
        {'bar': 'foo'}
      ],
      [
        {'foo': 'bar'}
      ]
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
