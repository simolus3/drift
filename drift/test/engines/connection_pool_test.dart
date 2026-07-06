import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/src/runtime/cancellation_zone.dart';
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
        {'foo': 'bar'},
      ];
    });

    final result = await multi.runSelect('statement', [1, 2]);

    verify(read.runSelect('statement', [1, 2]));
    verifyNever(write.runSelect(any, any));

    expect(result, [
      {'foo': 'bar'},
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
          {'foo': 'bar'},
        ],
      );
    });

    when(secondRead.runSelect(any, any)).thenAnswer((_) async {
      return [
        {'bar': 'foo'},
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
      {'foo': 'bar'},
    ]);

    verify(secondRead.runSelect('statement', [2]));
    verifyNever(write.runSelect(any, any));
    expect(secondResult, [
      {'bar': 'foo'},
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

  test('select failure does not cause an unhandled exception', () async {
    // https://github.com/simolus3/drift/issues/2323
    final read2 = MockExecutor();
    final multi = MultiExecutor.withReadPool(
      reads: [read2, read],
      write: write,
    );

    when(read2.runSelect(any, any)).thenThrow('bang!');

    await multi.ensureOpen(db);

    expect(multi.runSelect('select 1', []), throwsA(isA<String>()));
  });

  group('with cancellation zones', () {
    // https://github.com/simolus3/drift/issues/3824
    late MockExecutor read2;

    setUp(() {
      read2 = MockExecutor();
      multi = MultiExecutor.withReadPool(reads: [read, read2], write: write);
      db = TodoDb(multi);
    });

    /// Stubs selects on [executor] to respect cancellations like a real
    /// executor would.
    ///
    /// Selects for statements in [pending] complete when the completer
    /// returned for them is completed, all other selects complete directly.
    Map<String, Completer<List<Map<String, Object?>>>> stubSelects(
      MockExecutor executor,
      List<String> pending,
    ) {
      final completers = {
        for (final statement in pending)
          statement: Completer<List<Map<String, Object?>>>(),
      };

      when(executor.runSelect(any, any)).thenAnswer((invocation) {
        checkIfCancelled();
        final statement = invocation.positionalArguments[0] as String;
        return completers[statement]?.future ??
            Future.value([
              {'answer': 42},
            ]);
      });

      return completers;
    }

    test('does not leak them into unrelated queued selects', () async {
      await multi.ensureOpen(db);
      final firstPending = stubSelects(read, ['slow1']);
      final secondPending = stubSelects(read2, ['slow2']);

      // Occupy both readers with selects running in their own cancellation
      // zones, like stream query fetches would.
      runCancellable(() => multi.runSelect('slow1', []));
      final second = runCancellable(() => multi.runSelect('slow2', []));

      // With the pool saturated, this unrelated select gets queued. It is
      // not issued from a cancellation zone, so nothing may cancel it.
      final queued = multi.runSelect('queued', []);

      // Cancel the second select and let its statement finish, which makes
      // the pool dequeue the queued select. That select must not be affected
      // by the cancelled zone of the select that freed up the reader.
      second.cancel();
      secondPending['slow2']!.complete(const []);

      expect(await queued, [
        {'answer': 42},
      ]);

      firstPending['slow1']!.complete(const []);
      await pumpEventQueue();
    });

    test('still cancels queued selects issued inside of them', () async {
      await multi.ensureOpen(db);
      final firstPending = stubSelects(read, ['slow1']);
      final secondPending = stubSelects(read2, ['slow2']);

      // Occupy both readers with selects that don't support cancellation.
      final slow1 = multi.runSelect('slow1', []);
      final slow2 = multi.runSelect('slow2', []);

      // Queue a select from a cancellation zone, then cancel it before a
      // reader becomes available.
      final cancelled = runCancellable(() => multi.runSelect('queued', []));
      cancelled.cancel();

      // When a reader frees up and the queued select is started, it should
      // be cancelled just like it would have been without the pool.
      firstPending['slow1']!.complete(const []);

      expect(cancelled.result, throwsA(isA<CancellationException>()));

      secondPending['slow2']!.complete(const []);
      await slow1;
      await slow2;
    });
  });
}
