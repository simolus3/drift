@TestOn('vm')
@Timeout(Duration(seconds: 120))
import 'dart:async';

import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/src/remote/protocol.dart';
import 'package:drift_network_bridge/implementation/mqtt_database_gateway.dart';
import 'package:drift_testcases/database/database.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import '../../../drift/test/generated/todos.dart';
import '../../../drift/test/test_utils/database_vm.dart';
import '../../../drift/test/test_utils/mocks.dart';
void main() {
  preferLocalSqlite3();
  test('closes channel in shutdown mqtt ', () async {
    final gate = MqttDatabaseGateway('test.mosquitto.org',
        'unit_device', 'drift/test_site',
        allowRemoteShutdown: true);
    await gate.serve(Database(testInMemoryDatabase()));
    final client = gate.createConnection();
    await client.connect();
    await gate.isReady;
    await shutdown(client.expectedToClose);
  });

  test('can shutdown server on close', () async {
    final gate = MqttDatabaseGateway('test.mosquitto.org',
        'unit_device', 'drift/test_site',
        allowRemoteShutdown: true);
    await gate.serve(Database(testInMemoryDatabase()));
    final client = gate.createConnection();
    await client.connect();
    await gate.isReady;

    final clientConn = await connectToRemoteAndInitialize(
        client.expectedToClose,
        singleClientMode: true);
    final db = TodoDb(clientConn);

    await db.todosTable.select().get();
    await db.close();

    expect(gate.done, completes);
  });

  test(
    'does not send table update notifications in single client mode',
    () async {
      final gate = MqttDatabaseGateway('test.mosquitto.org', 'unit_device', 'drift/test_site',
          allowRemoteShutdown: true);
      await gate.serve(Database(testInMemoryDatabase()),serialize: false);
      final client = gate.createConnection();
      await client.connect();
      await gate.isReady;

      final clientConn = await connectToRemoteAndInitialize(
        client.transformSink(StreamSinkTransformer.fromHandlers(
          handleData: (data, out) {
            expect(data, isNot(isA<NotifyTablesUpdated>()));
            out.add(data);
          },
        )),
        serialize: false,
        singleClientMode: true,
      );

      final db = TodoDb(clientConn);
      await db.todosTable.select().get();
      await db.close();
    },
  );

  test('can run protocol without using complex types', () async {
    final executor = MockExecutor();
    // final server = DriftServer(DatabaseConnection(executor));
    // addTearDown(server.shutdown);

    final gate = MqttDatabaseGateway('test.mosquitto.org', 'unit_device', 'drift/test_site',
        allowRemoteShutdown: true);
    addTearDown(gate.shutdown);


    gate.changeStream(_checkStreamOfSimple);

    await gate.serveExecuter(DatabaseConnection(executor),serialize: true);

    // server.serve(host.changeStream(_checkStreamOfSimple), serialize: true);

    final client = gate.createConnection();
    await client.connect();
    await gate.isReady;

    final connection = await connectToRemoteAndInitialize(
        client.changeStream(_checkStreamOfSimple).expectedToClose,
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

    await db.close();
  });

  test('nested transactions', () async {
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

    // final server = DriftServer(DatabaseConnection(executor));
    // server.serve(host);
    final gate = MqttDatabaseGateway('test.mosquitto.org', 'unit_device', 'drift/test_site',
        allowRemoteShutdown: true);
    // addTearDown(server.shutdown);
    addTearDown(gate.shutdown);
    await gate.serveExecuter(DatabaseConnection(executor));

    final client = gate.createConnection();
    await client.connect();
    await gate.isReady;

    final db = TodoDb(await connectToRemoteAndInitialize(client));
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

  test('reports correct dialect of remote', () async {
    final executor = MockExecutor();
    when(executor.dialect).thenReturn(SqlDialect.postgres);

    final gate = MqttDatabaseGateway('test.mosquitto.org', 'unit_device', 'drift/test_site',
        allowRemoteShutdown: true);
    // addTearDown(server.shutdown);
    addTearDown(gate.shutdown);
    await gate.serveExecuter(DatabaseConnection(executor));

    final client = gate.createConnection();
    await client.connect();
    await gate.isReady;

    // final server = DriftServer(DatabaseConnection(executor))..serve(host);

    final clientConn = await connectToRemoteAndInitialize(client);
    // await server.shutdown();
    await gate.shutdown();
    expect(clientConn.executor.dialect, SqlDialect.postgres);
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

extension<T> on StreamChannel<T> {
  StreamChannel<T> get expectedToClose {
    return transformStream(StreamTransformer.fromHandlers(
      handleDone: expectAsync1((out) {
        out.close();
      }
    )));
  }
}
