@TestOn('vm')
import 'dart:async';

import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/src/remote/protocol.dart';
import 'package:drift/src/utils/synchronized.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'generated/todos.dart';
import 'test_utils/database_vm.dart';
import 'test_utils/mocks.dart';

void main() {
  preferLocalSqlite3();

  test('closes channel in shutdown', () async {
    final controller = StreamChannelController<Object?>();
    final server =
        DriftServer(testInMemoryDatabase(), allowRemoteShutdown: true);
    server.serve(controller.foreign);

    await shutdown(controller.local.expectedToClose);
  });

  test('can shutdown server on close', () async {
    final controller = StreamChannelController<Object?>();
    final server =
        DriftServer(testInMemoryDatabase(), allowRemoteShutdown: true);
    server.serve(controller.foreign);

    final client = await connectToRemoteAndInitialize(
        controller.local.expectedToClose,
        singleClientMode: true);
    final db = TodoDb(client);

    await db.todosTable.select().get();
    await db.close();

    expect(server.done, completes);
  });

  test(
    'does not send table update notifications in single client mode',
    () async {
      final server =
          DriftServer(testInMemoryDatabase(), allowRemoteShutdown: true);
      final controller = StreamChannelController<Object?>();
      server.serve(controller.foreign, serialize: false);

      final client = await connectToRemoteAndInitialize(
        controller.local.transformSink(StreamSinkTransformer.fromHandlers(
          handleData: (data, out) {
            expect(data, isNot(isA<NotifyTablesUpdated>()));
            out.add(data);
          },
        )),
        serialize: false,
        singleClientMode: true,
      );

      final db = TodoDb(client);
      await db.todosTable.select().get();
      await db.close();
    },
  );

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

    final mapped = _checkSimpleRoundtrip(protocol, request);
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

    final response = SuccessResponse(
        1,
        SelectResult([
          {'col': BigInt.one}
        ]));
    final mappedResponse = _checkSimpleRoundtrip(protocol, response);
    expect(
      mappedResponse,
      isA<SuccessResponse>().having((e) => e.requestId, 'requestId', 1).having(
            (e) => e.response,
            'response',
            isA<SelectResult>().having(
              (e) => e.rows,
              'rows',
              ([
                {'col': BigInt.one}
              ]),
            ),
          ),
    );

    final batchRequest = _checkSimpleRoundtrip(
      protocol,
      Request(
        1,
        ExecuteBatchedStatement(BatchedStatements(
          ['SELECT ?'],
          [
            ArgumentsForBatchedStatement(0, [BigInt.zero]),
            ArgumentsForBatchedStatement(0, [BigInt.one]),
            ArgumentsForBatchedStatement(0, [BigInt.two]),
          ],
        )),
      ),
    );
    expect(
      batchRequest,
      isA<Request>().having((e) => e.id, 'id', 1).having(
            (e) => e.payload,
            'payload',
            isA<ExecuteBatchedStatement>().having(
              (e) => e.stmts,
              'stmts',
              BatchedStatements(
                ['SELECT ?'],
                [
                  ArgumentsForBatchedStatement(0, [BigInt.zero]),
                  ArgumentsForBatchedStatement(0, [BigInt.one]),
                  ArgumentsForBatchedStatement(0, [BigInt.two]),
                ],
              ),
            ),
          ),
    );
  });

  test('can run protocol without using complex types', () async {
    final executor = MockExecutor();
    final server = DriftServer(DatabaseConnection(executor));
    addTearDown(server.shutdown);

    final channelController = StreamChannelController<Object?>();
    server.serve(channelController.foreign.changeStream(_checkStreamOfSimple),
        serialize: true);

    final connection = await connectToRemoteAndInitialize(
        channelController.local
            .changeStream(_checkStreamOfSimple)
            .expectedToClose,
        serialize: true);
    final db = TodoDb(connection);

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

    when(executor.runInsert(any, any)).thenAnswer(
        (realInvocation) => Future.error(UnimplementedError('error!')));
    await expectLater(
      db.categories
          .insertOne(CategoriesCompanion.insert(description: 'description')),
      throwsA(isA<DriftRemoteException>().having(
          (e) => e.remoteCause, 'remoteCause', 'UnimplementedError: error!')),
    );

    final statements =
        BatchedStatements(['SELECT 1'], [ArgumentsForBatchedStatement(0, [])]);
    when(executor.runBatched(any)).thenAnswer((i) => Future.value());
    // Not using db.batch because that starts a transaction, we want to test
    // this working with the default executor.
    // Regression test for: https://github.com/simolus3/drift/pull/2707
    await db.executor.runBatched(statements);
    verify(executor.runBatched(statements));

    await db.close();
  });

  test('nested transactions', () async {
    final controller = StreamChannelController<Object?>();
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

    final db = TodoDb(await connectToRemoteAndInitialize(controller.local));
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

  test('handles exclusive executors', () async {
    final controller = StreamChannelController<Object?>();
    final executor = MockExecutor();
    final multi = MultiChannel<Object?>(controller.local);

    final testEvents = StreamController<String>();
    final testEventQueue = StreamQueue(testEvents.stream);
    final lock = Lock();

    final server = DriftServer(DatabaseConnection(executor));
    controller.foreign.serveMulti(server);
    addTearDown(server.shutdown);

    final a = TodoDb(await multi.newRemoteConnection());
    final b = TodoDb(await multi.newRemoteConnection());

    final exclusiveA = MockExecutor();
    final exclusiveB = MockExecutor();

    var exclusiveCount = 0;
    when(executor.beginExclusive()).thenAnswer(expectAsync1((_) {
      if (exclusiveCount == 0) {
        exclusiveCount++;
        testEvents.add('try-a');
        return exclusiveA;
      } else {
        testEvents.add('try-b');
        return exclusiveB;
      }
    }, count: 2, id: 'beginExclusive'));

    for (final (name, executor) in [('a', exclusiveA), ('b', exclusiveB)]) {
      final closeCompleter = Completer<void>();

      when(executor.ensureOpen(any)).thenAnswer((i) {
        if (!executor.opened) {
          return expectAsync0(() async {
            await Future<void>.delayed(Duration.zero);

            final ready = Completer<bool>();
            lock.synchronized(() {
              testEvents.add('grant-$name');
              ready.complete(true);
              executor.opened = true;
              return closeCompleter.future;
            });

            return ready.future;
          }, id: 'ensureOpen-$name')();
        } else {
          return Future.value(true);
        }
      });

      when(executor.close()).thenAnswer(expectAsync1((_) async {
        testEvents.add('close-$name');
        closeCompleter.complete();
      }, id: 'close-$name'));
    }

    final wait = Completer<void>();
    a.exclusively(() async {
      await a.customSelect('SELECT 1').get();
      await wait.future;
    });

    b.exclusively(() async {
      await b.customSelect('SELECT 1').get();
    });

    await expectLater(
      testEventQueue,
      emitsInOrder(['try-a', 'grant-a']),
    );

    wait.complete();
    await expectLater(
      testEventQueue,
      emitsInOrder(['close-a', 'try-b', 'grant-b', 'close-b']),
    );
  });

  test('reports correct dialect of remote', () async {
    final executor = MockExecutor();
    when(executor.dialect).thenReturn(SqlDialect.postgres);

    final controller = StreamChannelController<Object?>();
    final server = DriftServer(DatabaseConnection(executor))
      ..serve(controller.foreign);

    final client = await connectToRemoteAndInitialize(controller.local);
    await server.shutdown();
    expect(client.executor.dialect, SqlDialect.postgres);
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

Message _checkSimpleRoundtrip(DriftProtocol protocol, Message source) {
  final serialized = protocol.serialize(source);
  _checkSimple(serialized);
  return protocol.deserialize(serialized!);
}

extension<T> on StreamChannel<T> {
  StreamChannel<T> get expectedToClose {
    return transformStream(StreamTransformer.fromHandlers(
      handleDone: expectAsync1((out) => out.close()),
    ));
  }

  void serveMulti(DriftServer server) {
    final multi = MultiChannel<T>(this);
    multi.stream.listen((message) {
      server.serve(multi.virtualChannel(message as int));
    });
  }
}

extension on MultiChannel<Object?> {
  Future<DatabaseConnection> newRemoteConnection() async {
    final channel = virtualChannel();
    sink.add(channel.id);

    return await connectToRemoteAndInitialize(channel);
  }
}
