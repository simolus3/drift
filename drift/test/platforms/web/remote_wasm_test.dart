@TestOn('browser')
library;

import 'package:drift/remote.dart';
import 'package:drift/src/web/channel_new.dart';
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
    runAllTests(_RemoteWebExecutor(true));
  });
}

final class _RemoteWebExecutor extends TestExecutor {
  final bool _newSerialization;

  final InMemoryFileSystem _fs = InMemoryFileSystem();

  _RemoteWebExecutor(this._newSerialization);

  @override
  bool get supportsNestedTransactions => true;

  @override
  bool get supportsReturning => true;

  @override
  DatabaseConnection createConnection() {
    return DatabaseConnection.delayed(Future(() async {
      final sqlite = await sqlite3;
      sqlite.registerVirtualFileSystem(_fs, makeDefault: true);

      final server = DriftServer(
        WasmDatabase(
          sqlite3: sqlite,
          path: '/db',
        ),
        allowRemoteShutdown: true,
      );
      final channel = MessageChannel();
      final clientChannel = channel.port2.channel(
        explicitClose: true,
        webNativeSerialization: _newSerialization,
      );

      server.serve(
        channel.port1.channel(
          explicitClose: true,
          webNativeSerialization: _newSerialization,
        ),
        serialize: !_newSerialization,
      );

      return await connectToRemoteAndInitialize(
        clientChannel,
        singleClientMode: true,
        serialize: !_newSerialization,
      );
    }));
  }

  @override
  Future deleteData() async {
    _fs.fileData.clear();
  }
}
