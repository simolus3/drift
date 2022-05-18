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
    final server = DriftServer(DatabaseConnection.fromExecutor(executor));
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
