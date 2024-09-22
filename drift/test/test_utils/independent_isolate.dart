import 'dart:isolate';

import 'package:drift/isolate.dart';
import 'package:mockito/mockito.dart';

import 'test_utils.dart';

void main(List<String> args, SendPort message) {
  spawnIsolate(message);
}

void spawnIsolate(SendPort sendConnectPortTo) async {
  final isolate = DriftIsolate.inCurrent(
    () {
      final executor = MockExecutor();
      when(executor.runSelect(any, any)).thenAnswer((i) async {
        final args = i.positionalArguments[1];
        return [
          {'a': args[0]}
        ];
      });
      return executor;
    },
    shutdownAfterLastDisconnect: true,
    killIsolateWhenDone: true,
  );

  sendConnectPortTo.send(isolate.connectPort);
}
