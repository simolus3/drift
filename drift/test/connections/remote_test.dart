import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:drift/connections/remote.dart';
import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:drift/src/connections/remote/channel.dart';
import 'package:drift/src/connections/remote/protocol.dart';
import 'package:drift/src/connections/remote/serialize.dart';
import 'package:drift/src/utils/synchronized.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import '../generated/todos.dart';
import '../test_utils/test_utils.dart';

void main() {
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

    final client = connectToRemote(
      dialect: const SqliteDialect(),
      channel: controller.local.expectedToClose,
      singleClientMode: true,
    );
    final db = TodoDb(client);

    await db.select(db.todosTable).get();
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

      final client = connectToRemote(
        dialect: const SqliteDialect(),
        channel:
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
      await db.select(db.todosTable).get();
      await db.close();
    },
  );

  test('Uint8Lists are mapped from and to Uint8Lists', () async {
    const protocol = ProtocolMessageSerializer();

    final request = ExecuteRequest(
      1,
      sessionId: 2,
      statement: StatementInfo.fromText('SELECT ?', variables: [
        (BuiltinDriftType.byteArray, Uint8List.fromList([1, 2, 3]))
      ]),
    );

    final mapped = protocol.decode(protocol.encode(request));
    expect(
      mapped,
      isA<ExecuteRequest>()
          .having((e) => e.id, 'id', 1)
          .having((e) => e.sessionId, 'sessionId', 2)
          .having(
            (e) => e.statement,
            'statement',
            isA<StatementInfo>().having((e) => e.sql, 'sql', 'SELECT ?').having(
                (e) => e.variables.map((e) => e.$2),
                'variables',
                [isA<Uint8List>()]),
          ),
    );
  });

  test('BigInts are serialied', () {
    const protocol = ProtocolMessageSerializer();

    final request = ExecuteRequest(
      1,
      sessionId: 2,
      statement: StatementInfo.fromText('SELECT ?',
          variables: [(BuiltinDriftType.int64, BigInt.one)]),
    );

    final mapped = _checkSimpleRoundtrip(protocol, request);
    expect(
      mapped,
      isA<ExecuteRequest>().having(
        (e) => e.statement,
        'statement',
        isA<StatementInfo>().having((e) => e.sql, 'sql', 'SELECT ?').having(
            (e) => e.variables.map((e) => e.$2), 'variables', [isA<BigInt>()]),
      ),
    );

    final response = ExecuteResponse(1, result: [
      queryResult([
        {'col': BigInt.one}
      ])
    ]);
    final mappedResponse = _checkSimpleRoundtrip(protocol, response);
    expect(mappedResponse,
        isA<ExecuteResponse>().having((e) => e.requestId, 'requestId', 1));

    expect(
        (mappedResponse as ExecuteResponse)
            .result
            .single
            .resultSet!
            .single
            .byName('col'),
        BigInt.one);

    final batchRequest = _checkSimpleRoundtrip(
      protocol,
      ExecuteBatchRequest(
        1,
        sessionId: 2,
        batch: StatementBatch(
          sql: ['SELECT ?'],
          statements: [
            StatementInBatch(
              0,
              StatementInfo.fromText(
                'SELECT ?',
                variables: [(BuiltinDriftType.int64, BigInt.zero)],
              ),
            ),
            StatementInBatch(
              0,
              StatementInfo.fromText(
                'SELECT ?',
                variables: [(BuiltinDriftType.int64, BigInt.one)],
              ),
            ),
            StatementInBatch(
              0,
              StatementInfo.fromText(
                'SELECT ?',
                variables: [(BuiltinDriftType.int64, BigInt.two)],
              ),
            ),
          ],
        ),
      ),
    );
    expect(
      batchRequest,
      isA<ExecuteBatchRequest>().having((e) => e.id, 'id', 1).having(
            (e) => e.batch,
            'batch',
            isA<StatementBatch>()
                .having((e) => e.sql, 'sql', ['SELECT ?']).having(
              (e) => e.statements,
              'statements',
              [
                isStatementInBatch(0, [BigInt.zero]),
                isStatementInBatch(0, [BigInt.one]),
                isStatementInBatch(0, [BigInt.two]),
              ],
            ),
          ),
    );
  });

  test('can run protocol without using complex types', () async {
    final executor = MockSession();
    final server = DriftServer(createConnection(executor));
    addTearDown(server.shutdown);

    final channelController = StreamChannelController<Object?>();
    server.serve(channelController.foreign.changeStream(_checkStreamOfSimple),
        serialize: true);

    final connection = connectToRemote(
      channel: channelController.local
          .changeStream(_checkStreamOfSimple)
          .expectedToClose,
      serialize: true,
      dialect: const SqliteDialect(),
    );
    final db = TodoDb(connection);

    await db.customSelect('SELECT ?, ?, ?, ?', variables: [
      (BuiltinDriftType.int64, BigInt.one),
      (BuiltinDriftType.bool, true),
      (BuiltinDriftType.double, 1.2),
      (BuiltinDriftType.byteArray, Uint8List(12)),
    ]).get();
    verify(executor.executeSql('SELECT ?, ?, ?, ?', [
      BigInt.one,
      1,
      1.2,
      Uint8List(12),
    ]));

    when(executor.execute(any)).thenAnswer(
        (realInvocation) => Future.error(UnimplementedError('error!')));
    await expectLater(
      db
          .into(db.categories)
          .insert(CategoriesCompanion.insert(description: 'description')),
      throwsA(isA<DriftRemoteException>().having(
          (e) => e.remoteCause, 'remoteCause', 'UnimplementedError: error!')),
    );

    final statements = StatementBatch(
      sql: ['SELECT 1'],
      statements: [StatementInBatch(0, StatementInfo.fromText('SELECT 1'))],
    );
    when(executor.executeBatch(any)).thenAnswer((i) => Future.value([]));
    // Not using db.batch because that starts a transaction, we want to test
    // this working with the default executor.
    // Regression test for: https://github.com/simolus3/drift/pull/2707
    await (await db.currentSession()).executeBatch(statements);
    verify(executor.executeBatch(statements));

    // Regression test for https://github.com/simolus3/drift/issues/3194
    await db.transaction(() async {
      await db.customUpdate('DELETE FROM "users" WHERE 0');
    });

    await db.close();
  });

  test('nested transactions', () async {
    final controller = StreamChannelController<Object?>();
    final executor = MockSession();
    final outerTransaction = executor.transactions;
    // avoid this object being created implicitly in the beginTransaction() when
    // stub because that breaks mockito.
    outerTransaction.transactions; // ignore: unnecessary_statements
    final innerTransactions = <MockSession>[];

    Future<DriftSession> newTransaction(Invocation _) async {
      final transaction = MockSession();
      innerTransactions.add(transaction);
      when(transaction.begin(any)).thenAnswer(newTransaction);
      return transaction;
    }

    when(outerTransaction.begin(any)).thenAnswer(newTransaction);

    final server = DriftServer(DriftDatabaseImplementation(
      dialect: const SqliteDialect(),
      openConnection: () async => executor,
    ));
    server.serve(controller.foreign);
    addTearDown(server.shutdown);

    final db = TodoDb(connectToRemote(
        dialect: const SqliteDialect(), channel: controller.local));
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

    verify(outerTransaction.begin(any));
    verify(innerTransactions[0].rollback());
    verify(innerTransactions[1].begin(any));
    verify(innerTransactions[2].commit());
    verify(innerTransactions[1].commit());
    verify(outerTransaction.commit());
  });

  test('handles exclusive executors', () async {
    final controller = StreamChannelController<Object?>();
    final executor = MockSession();
    final multi = MultiChannel<Object?>(controller.local);

    final testEvents = StreamController<String>();
    final testEventQueue = StreamQueue(testEvents.stream);
    final lock = Lock();

    final server = DriftServer(DriftDatabaseImplementation(
      dialect: const SqliteDialect(),
      openConnection: () async => executor,
    ));
    controller.foreign.serveMulti(server);
    addTearDown(server.shutdown);

    final a = TodoDb(multi.newRemoteConnection());
    final b = TodoDb(multi.newRemoteConnection());

    final exclusiveA = MockSession();
    final exclusiveB = MockSession();

    var exclusiveCount = 0;

    when(executor.exclusive()).thenAnswer(expectAsync1((_) async {
      String name;
      MockSession inner;

      if (exclusiveCount == 0) {
        exclusiveCount++;
        name = 'a';
        inner = exclusiveA;
      } else {
        name = 'b';
        inner = exclusiveB;
      }

      testEvents.add('try-$name');
      await Future<void>.delayed(Duration.zero);

      final ready = Completer<bool>();

      lock.synchronized(() async {
        testEvents.add('grant-$name');
        ready.complete(true);
        await inner.closed;
        testEvents.add('close-$name');
      });

      await ready.future;
      return inner;
    }, count: 2, id: 'beginExclusive'));

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
      emitsInOrder(['try-a', 'try-b']),
    );

    wait.complete();
    await expectLater(
      testEventQueue,
      emitsInOrder(['grant-a', 'close-a', 'grant-b', 'close-b']),
    );
  });
}

Stream<Object?> _checkStreamOfSimple(Stream<Object?> source) {
  return source.map((event) {
    _checkSimple(event);
    return transportRoundtrip(event);
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

ProtocolMessage _checkSimpleRoundtrip(
    ProtocolMessageSerializer serializer, ProtocolMessage source) {
  final serialized = serializer.encode(source);
  _checkSimple(serialized);
  return serializer.decode(serialized);
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
  DriftDatabaseImplementation newRemoteConnection() {
    final channel = virtualChannel();
    sink.add(channel.id);

    return connectToRemote(channel: channel, dialect: const SqliteDialect());
  }
}
