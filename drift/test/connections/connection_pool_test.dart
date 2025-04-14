import 'package:drift/drift.dart';
import 'package:drift/src/connections/connection_pool.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
  late MockSession read, write;
  late DriftSessionPool pool;
  late TodoDb db;

  setUp(() {
    read = MockSession();
    write = MockSession();

    pool = DriftSessionPool(reads: [read], write: write);
    db = TodoDb(createConnection(pool));
  });

  test('uses write session for schema version', () async {
    await db.initialize();

    verify(write.schemaVersion);
    verify(write.writeSchemaVersion(db.schemaVersion));

    verifyZeroInteractions(read);
  });

  test('runs selects on the reading executor', () async {
    await db.initialize();
    clearInteractions(write);

    when(read.execute(any)).thenAnswer((_) async {
      return queryResult([
        {'foo': 'bar'}
      ]);
    });

    final result = await pool.execute(StatementInfo.fromText(
      'statement',
      variables: [(BuiltinDriftType.int, 1), (BuiltinDriftType.int, 2)],
      isReadOnly: true,
    ));

    verify(read.executeSql('statement', [1, 2]));
    verifyNever(write.execute(any));

    expect(result.resultSet, hasLength(1));
  });

  test('runs selects on reads executor does not block', () async {
    final secondRead = MockSession();

    pool = DriftSessionPool(reads: [read, secondRead], write: write);
    db = TodoDb(createConnection(pool));

    await db.initialize();
    clearInteractions(read);
    clearInteractions(secondRead);
    clearInteractions(write);

    when(read.execute(any)).thenAnswer((_) {
      return Future.delayed(
          const Duration(milliseconds: 10),
          () => queryResult([
                {'foo': 'bar'}
              ]));
    });

    when(secondRead.execute(any)).thenAnswer((_) async {
      return queryResult([
        {'bar': 'foo'}
      ]);
    });

    final firstFuture = pool.execute(StatementInfo.fromText('statement',
        variables: [(BuiltinDriftType.int, 1)], isReadOnly: true));
    final secondFuture = pool.execute(StatementInfo.fromText('statement',
        variables: [(BuiltinDriftType.int, 2)], isReadOnly: true));

    final fasterResult = await Future.any([firstFuture, secondFuture]);
    final firstResult = await firstFuture;
    final secondResult = await secondFuture;

    assert(fasterResult == secondResult);

    verify(read.executeSql('statement', [1]));
    verifyNever(write.execute(any));
    expect(firstResult.resultSet!.single.byName('foo'), 'bar');

    verify(secondRead.executeSql('statement', [2]));
    expect(secondResult.resultSet!.single.byName('bar'), 'foo');
  });

  test('runs updates on the writing executor', () async {
    await db.initialize();

    await pool.execute(StatementInfo.fromText('write'));
    verify(write.executeSql('write', []));

    await pool.executeBatch([]);
    verify(write.executeBatch([]));
  });

  test('runs transactions on the writing executor', () async {
    await db.initialize();

    final transaction = await pool.begin(TransactionOptions());
    await transaction
        .execute(StatementInfo.fromText('select', isReadOnly: true));

    verify(write.begin(any));
    verify(write.transactions.executeSql('select', []));
  });

  test('select failure does not cause an unhandled exception', () async {
    // https://github.com/simolus3/drift/issues/2323
    final read2 = MockSession();
    final multi = DriftSessionPool(reads: [read2, read], write: write);

    when(read2.execute(any)).thenThrow('bang!');
    await db.initialize();

    expect(multi.execute(StatementInfo.fromText('select 1', isReadOnly: true)),
        throwsA('bang!'));
  });
}
