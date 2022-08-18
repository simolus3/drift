@TestOn('vm')
import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/src/remote/protocol.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'generated/todos.dart';
import 'test_utils/database_vm.dart';
import 'test_utils/mocks.dart';

void main() {
  test('closes channel in shutdown', () async {
    final controller = StreamChannelController();
    final server =
        DriftServer(testInMemoryDatabase(), allowRemoteShutdown: true);
    server.serve(controller.foreign);

    final transformed = controller.local.transformSink(
      StreamSinkTransformer.fromHandlers(
        handleDone: expectAsync1((inner) => inner.close()),
      ),
    );

    await shutdown(transformed);
  });

  test('Uint8Lists are mapped from and to Uint8Lists', () async {
    const protocol = DriftProtocol();

    final request = Request(
      1,
      ExecuteQuery(StatementMethod.select, 'SELECT ?', [
        Uint8List.fromList([1, 2, 3])
      ]),
    );

    final mapped = protocol.deserialize(protocol.serialize(request)!);
    expect(
      mapped,
      isA<Request>().having((e) => e.id, 'id', 1).having(
            (e) => e.payload,
            'payload',
            isA<ExecuteQuery>()
                .having((e) => e.method, 'method', StatementMethod.select)
                .having((e) => e.args, 'args', [isA<Uint8List>()]),
          ),
    );
  });

  test('BigInts are serialied', () {
    const protocol = DriftProtocol();

    final request = Request(
      1,
      ExecuteQuery(StatementMethod.select, 'SELECT ?', [BigInt.one]),
    );

    final mapped = protocol.deserialize(protocol.serialize(request)!);
    expect(
      mapped,
      isA<Request>().having((e) => e.id, 'id', 1).having(
            (e) => e.payload,
            'payload',
            isA<ExecuteQuery>()
                .having((e) => e.method, 'method', StatementMethod.select)
                .having((e) => e.args, 'args', [isA<BigInt>()]),
          ),
    );
  });

  test('can run protocol without using complex types', () async {
    final executor = MockExecutor();
    final server = DriftServer(DatabaseConnection(executor));
    addTearDown(server.shutdown);

    final channelController = StreamChannelController();
    server.serve(channelController.foreign.changeStream(_checkStreamOfSimple),
        serialize: true);

    final connection = remote(
        channelController.local.changeStream(_checkStreamOfSimple),
        serialize: true);
    final db = TodoDb.connect(connection);

    await db.customSelect('SELECT ?, ?, ?, ?', variables: [
      Variable.withBigInt(BigInt.one),
      Variable.withBool(true),
      Variable.withReal(1.2),
      Variable.withBlob(Uint8List(12)),
    ]).get();
    verify(executor.runSelect('SELECT ?, ?, ?, ?', [
      BigInt.one,
      1,
      1.2,
      Uint8List(12),
    ]));
  });

  test('nested transactions', () async {
    final controller = StreamChannelController();
    final executor = MockExecutor();
    final outerTransaction = executor.transactions;
    // avoid this object being created implicitly in the beginTransaction() when
    // stub because that breaks mockito.
    outerTransaction.transactions; // ignore: unnecessary_statements
    final innerTransactions = <MockTransactionExecutor>[];

    TransactionExecutor newTransaction(Invocation _) {
      final transaction = MockTransactionExecutor()..transactions;
      innerTransactions.add(transaction);
      when(transaction.beginTransaction()).thenAnswer(newTransaction);
      return transaction;
    }

    when(outerTransaction.beginTransaction()).thenAnswer(newTransaction);

    final server = DriftServer(DatabaseConnection(executor));
    server.serve(controller.foreign);
    addTearDown(server.shutdown);

    final db = TodoDb.connect(remote(controller.local));
    addTearDown(db.close);

    await db.transaction(() async {
      final abortException = Exception('abort');

      await expectLater(db.transaction(() async {
        await db.select(db.todosTable).get();
        throw abortException;
      }), throwsA(abortException));

      await db.transaction(() async {
        await db.select(db.todosTable).get();

        await db.transaction(() => db.select(db.todosTable).get());
      });
    });

    verify(outerTransaction.beginTransaction());
    verify(innerTransactions[0].ensureOpen(any));
    verify(innerTransactions[0].rollback());
    verify(innerTransactions[1].ensureOpen(any));
    verify(innerTransactions[1].beginTransaction());
    verify(innerTransactions[2].ensureOpen(any));
    verify(innerTransactions[2].send());
    verify(innerTransactions[1].send());
    verify(outerTransaction.send());
  });
}

Stream<Object?> _checkStreamOfSimple(Stream<Object?> source) {
  return source.map((event) {
    _checkSimple(event);
    return event;
  });
}

void _checkSimple(Object? object) {
  if (object is String || object is num || object is bool || object == null) {
    // fine, these objects are allowed
  } else if (object is List) {
    // lists of simple objects are allowed too
    object.forEach(_checkSimple);
  } else {
    fail('Invalid message over wire: $object');
  }
}
