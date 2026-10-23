@TestOn('browser')
library;

import 'package:drift/remote.dart';
import 'package:drift/src/web/channel_new.dart';
import 'package:drift/src/web/wasm_setup/protocol.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';
import 'package:test/test.dart';

import 'package:drift_testcases/tests.dart';
import 'package:web/web.dart';
import '../../test_utils/database_web.dart';

void main() {
  group('with old serialization', () {
    runAllTests(_RemoteWebExecutor(false));
  });

  group('with new serialization', () {
    final executor = _RemoteWebExecutor(true);

    runAllTests(executor);

    test('recovers sqlite exceptions', () async {
      final connection = Database(executor.createConnection());
      await expectLater(
        () => connection
            .customSelect(
              'select throw(?);',
              variables: [Variable.withString('a')],
            )
            .get(),
        throwsA(
          isA<DriftRemoteException>().having(
            (e) => e.remoteCause,
            'remoteCause',
            isA<SqliteException>().having(
              (e) => e.toString(),
              'toString()',
              'SqliteException(1): while selecting from statement, "exception", SQL logic error (code 1)\n'
                  '  Causing statement: select throw(?);, parameters: a',
            ),
          ),
        ),
      );
    });
  });
}

final class _RemoteWebExecutor extends TestExecutor {
  final bool _newSerialization;

  final InMemoryFileSystem _fs = InMemoryFileSystem();
  var _didRegisterVfs = false;

  _RemoteWebExecutor(this._newSerialization);

  @override
  bool get supportsNestedTransactions => true;

  @override
  bool get supportsReturning => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.delayed(
      Future(() async {
        final sqlite = await sqlite3;
        if (!_didRegisterVfs) {
          sqlite.registerVirtualFileSystem(_fs, makeDefault: true);
          _didRegisterVfs = true;
        }

        final server = DriftServer(
          WasmDatabase(
            sqlite3: sqlite,
            path: '/db',
            setup: (database) => {
              database.createFunction(
                functionName: 'throw',
                function: (_) => throw 'exception',
                argumentCount: const AllowedArgumentCount(1),
              ),
            },
          ),
          allowRemoteShutdown: true,
        );
        final channel = MessageChannel();
        final clientChannel = channel.port2.channel(
          explicitClose: true,
          webNativeSerialization: _newSerialization,
          nativeSerializionVersion: ProtocolVersion.current.versionCode,
        );

        server.serve(
          channel.port1.channel(
            explicitClose: true,
            webNativeSerialization: _newSerialization,
            nativeSerializionVersion: ProtocolVersion.current.versionCode,
          ),
          serialize: !_newSerialization,
        );

        return await connectToRemoteAndInitialize(
          clientChannel,
          singleClientMode: true,
          serialize: !_newSerialization,
        );
      }),
    );
  }

  @override
  Future deleteData() async {
    _fs.fileData.clear();
  }
}
