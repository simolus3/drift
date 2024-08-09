import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'connect.dart';

@internal
bool hasConfiguredSqlite = false;

String portName(String databaseName) {
  return 'drift-db/$databaseName';
}

QueryExecutor driftDatabase({
  required String name,
  DriftWebOptions? web,
  DriftNativeOptions? native,
}) {
  return DatabaseConnection.delayed(Future(() async {
    if (!hasConfiguredSqlite) {
      // Also work around limitations on old Android versions
      if (Platform.isAndroid) {
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      }

      // Make sqlite3 pick a more suitable location for temporary files - the
      // one from the system may be inaccessible due to sandboxing.
      final cachebase = (await getTemporaryDirectory()).path;
      // We can't access /tmp on Android, which sqlite3 would try by default.
      // Explicitly tell it about the correct temporary directory.
      sqlite3.tempDirectory = cachebase;
    }

    if (native?.shareAcrossIsolates == true) {
      const connectTimeout = Duration(seconds: 1);

      while (true) {
        if (IsolateNameServer.lookupPortByName(portName(name))
            case final port?) {
          final isolate = DriftIsolate.fromConnectPort(port, serialize: false);
          try {
            return await isolate.connect(connectTimeout: connectTimeout);
          } on TimeoutException {
            // Isolate has stopped shortly after the register call. It should
            // also remove the port mapping, so we can just try again in another
            // iteration.
          }
        } else {
          // No port has been registered yet! Spawn an isolate that will try to
          // register itself.
          final dbFolder = await getApplicationDocumentsDirectory();
          final file = File(p.join(dbFolder.path, '$name.sqlite'));
          final receiveFromPending = ReceivePort();
          final firstMessage = receiveFromPending.first;
          await Isolate.spawn(
            _isolateEntrypoint,
            (
              name: name,
              options: native,
              sendResponses: receiveFromPending.sendPort,
              path: file.path,
            ),
            onExit: receiveFromPending.sendPort,
          );

          // The isolate will either succeed in registering its connect port to
          // the name server (in which case it sends us the port), or it fails
          // due to a race condition (in which case it exits).
          final first = await firstMessage;
          if (first case SendPort port) {
            return await DriftIsolate.fromConnectPort(port, serialize: false)
                .connect();
          }
        }
      }
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, '$name.sqlite'));

    return NativeDatabase.createBackgroundConnection(file);
  }));
}

typedef _EntrypointMessage = ({
  String name,
  String path,
  DriftNativeOptions? options,
  SendPort sendResponses,
});

void _isolateEntrypoint(_EntrypointMessage message) {
  final connections = ReceivePort();
  if (IsolateNameServer.registerPortWithName(
      connections.sendPort, portName(message.name))) {
    final server = DriftIsolate.inCurrent(
      () => NativeDatabase(File(message.path)),
      port: connections,
      beforeShutdown: () {
        IsolateNameServer.removePortNameMapping(portName(message.name));
      },
      killIsolateWhenDone: true,
    );

    message.sendResponses.send(server.connectPort);
  } else {
    // Another isolate is responsible for hosting this database, abort.
    connections.close();
    return;
  }
}
