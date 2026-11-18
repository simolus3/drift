@TestOn('vm')
library;

import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart' show QueryExecutor, SqlDialect;
import 'package:drift/isolate.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> main([List<String> args = const []]) async {
  if (args.contains('--probe')) {
    await _probeRetainedPorts();
    return;
  }

  test('disconnecting releases the client isolate exit listener', () async {
    // Use a separate VM so concurrent tests cannot affect the port count and
    // the VM service is available in an ordinary test run.
    final driftLibrary = (await Isolate.resolvePackageUri(
      Uri.parse('package:drift/drift.dart'),
    ))!;
    final probe = driftLibrary.resolve(
      '../test/isolate_exit_listener_test.dart',
    );
    final packages = (await Isolate.packageConfig)!;
    final process = await Process.run(Platform.resolvedExecutable, [
      '--enable-vm-service=0',
      '--packages=${packages.toFilePath()}',
      probe.toFilePath(),
      '--probe',
    ]);

    expect(process.exitCode, 0, reason: process.stderr as String);
    final counts = RegExp(
      r'^send ports: (\d+) (\d+)$',
      multiLine: true,
    ).firstMatch(process.stdout as String);
    expect(counts, isNotNull);
    final before = int.parse(counts!.group(1)!);
    final after = int.parse(counts.group(2)!);
    expect(
      after,
      lessThanOrEqualTo(before + 2),
      reason: 'Live send ports grew from $before to $after',
    );
  });
}

Future<void> _probeRetainedPorts() async {
  final address = (await developer.Service.getInfo()).serverUri!;
  final vm = await vmServiceConnectUri(
    address.replace(scheme: 'ws', path: '${address.path}ws').toString(),
  );
  final isolate = developer.Service.getIsolateId(Isolate.current)!;
  final server = DriftIsolate.inCurrent(_UnusedExecutor.new);
  try {
    Future<void> connectAndClose() async {
      final client = await server.connect();
      await client.streamQueries.close();
      await client.executor.close();
    }

    Future<int> liveSendPorts() async {
      // Exit-listener messages are handled asynchronously by the VM.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await vm.getAllocationProfile(isolate, gc: true);
      final profile = await vm.getAllocationProfile(isolate, gc: true);
      return profile.members!
          .where((entry) => entry.classRef?.name == '_SendPort')
          .fold<int>(
            0,
            (count, entry) => count + (entry.instancesCurrent ?? 0),
          );
    }

    for (var i = 0; i < 5; i++) {
      await connectAndClose();
    }
    final before = await liveSendPorts();
    for (var i = 0; i < 100; i++) {
      await connectAndClose();
    }
    print('send ports: $before ${await liveSendPorts()}');
  } finally {
    await server.shutdownAll();
    await vm.dispose();
  }
}

final class _UnusedExecutor implements QueryExecutor {
  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
