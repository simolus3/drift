@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:path/path.dart' as p;
import 'package:vm_service/vm_service_io.dart';

void main() {
  late Process child;
  late VmService vm;
  late String isolateId;

  setUpAll(() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();

    String sdk = p.dirname(p.dirname(Platform.resolvedExecutable));
    child = await Process.start(p.join(sdk, 'bin', 'dart'), [
      'run',
      '--enable-vm-service=$port',
      '--disable-service-auth-codes',
      '--enable-asserts',
      'test/integration_tests/devtools/app.dart',
    ]);

    final vmServiceListening = Completer<void>();
    final databaseOpened = Completer<void>();

    child.stdout
        .map(utf8.decode)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.startsWith('The Dart VM service is listening')) {
        vmServiceListening.complete();
      } else if (line == 'database created') {
        databaseOpened.complete();
      } else if (!line.startsWith('The Dart DevTools')) {
        print('[child]: $line');
      }
    });

    await vmServiceListening.future;

    vm = await vmServiceConnectUri('ws://localhost:$port/ws');
    await databaseOpened.future;

    final state = await vm.getVM();
    isolateId = state.isolates!.single.id!;
  });

  tearDownAll(() async {
    child.kill();
  });

  test('can list create statements', () async {
    final response = await vm.callServiceExtension(
      'ext.drift.database',
      args: {'action': 'collect-expected-schema', 'db': '0'},
      isolateId: isolateId,
    );

    expect(
        response.json!['r'],
        containsAll([
          'CREATE TABLE IF NOT EXISTS "categories" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "desc" TEXT NOT NULL UNIQUE, "priority" INTEGER NOT NULL DEFAULT 0, "description_in_upper_case" TEXT NOT NULL GENERATED ALWAYS AS (UPPER("desc")) VIRTUAL);',
          'CREATE TABLE IF NOT EXISTS "todos" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "title" TEXT NULL, "content" TEXT NOT NULL, "target_date" INTEGER NULL UNIQUE, "category" INTEGER NULL REFERENCES categories (id) DEFERRABLE INITIALLY DEFERRED, "status" TEXT NULL, UNIQUE ("title", "category"), UNIQUE ("title", "target_date"));',
          'CREATE TABLE IF NOT EXISTS "shared_todos" ("todo" INTEGER NOT NULL, "user" INTEGER NOT NULL, PRIMARY KEY ("todo", "user"), FOREIGN KEY (todo) REFERENCES todos(id), FOREIGN KEY (user) REFERENCES users(id));'
        ]));
  });
}
