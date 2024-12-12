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

String isolateControlPortName(String databaseName) {
  return 'drift-db/$databaseName/control';
}

QueryExecutor driftDatabase({
  required String name,
  DriftWebOptions? web,
  DriftNativeOptions? native,
}) {
  Future<File> databaseFile() async {
    if (native?.databasePath case final lookupPath?) {
      return File(await lookupPath());
    } else {
      final dbFolder = switch (native?.directory) {
        DriftDatabaseDirectory.applicationCacheDirectory =>
          await getApplicationCacheDirectory(),
        DriftDatabaseDirectory.applicationSupportDirectory =>
          await getApplicationSupportDirectory(),
        DriftDatabaseDirectory.applicationDocumentsDirectory ||
        null =>
          await getApplicationDocumentsDirectory(),
      };
      return File(p.join(dbFolder.path, '$name.sqlite'));
    }
  }

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
          final isolate = DriftIsolate.fromConnectPort(port);
          try {
            return await isolate.connect(connectTimeout: connectTimeout);
          } on TimeoutException {
            // Isolate has stopped shortly after the register call. It should
            // also remove the port mapping, so we can just try again in another
            // iteration.
            // However, it's possible for the isolate to become unreachable
            // without unregistering itself (either due to a fatal error or when
            // doing a hot restart). Check if the isolate is still reachable,
            // and remove the mapping if it's not.
            final controlPort = IsolateNameServer.lookupPortByName(
                isolateControlPortName(name));
            if (controlPort == null) {
              continue;
            }
            final supposedIsolate = Isolate(controlPort);
            if (!await supposedIsolate.pingWithTimeout()) {
              // Yup, gone!
              IsolateNameServer.removePortNameMapping(portName(name));
            }
            // Otherwise, the isolate is probably paused. Keep trying...
          }
        } else {
          // No port has been registered yet! Spawn an isolate that will try to
          // register itself as the database server.
          final receiveFromPending = ReceivePort();
          final firstMessage = receiveFromPending.first;
          await Isolate.spawn(
            _isolateEntrypoint,
            (
              name: name,
              options: native,
              sendResponses: receiveFromPending.sendPort,
              path: (await databaseFile()).path,
            ),
            onExit: receiveFromPending.sendPort,
          );

          // The isolate will either succeed in registering its connect port to
          // the name server (in which case it sends us the port), or it fails
          // due to a race condition (in which case it exits).
          final first = await firstMessage;
          if (first case SendPort port) {
            return await DriftIsolate.fromConnectPort(port).connect();
          }
        }
      }
    }

    return NativeDatabase.createBackgroundConnection(await databaseFile());
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
    final controlPortName = isolateControlPortName(message.name);
    final server = DriftIsolate.inCurrent(
      () => NativeDatabase(File(message.path)),
      port: connections,
      beforeShutdown: () {
        IsolateNameServer.removePortNameMapping(portName(message.name));
        IsolateNameServer.removePortNameMapping(controlPortName);
      },
      killIsolateWhenDone: true,
      shutdownAfterLastDisconnect: true,
    );

    message.sendResponses.send(server.connectPort);

    IsolateNameServer.removePortNameMapping(controlPortName);
    IsolateNameServer.registerPortWithName(
        Isolate.current.controlPort, controlPortName);
  } else {
    // Another isolate is responsible for hosting this database, abort.
    connections.close();
    return;
  }
}

extension PingWithTimeout on Isolate {
  Future<bool> pingWithTimeout(
      [Duration timeout = const Duration(milliseconds: 500)]) {
    final completer = Completer<bool>();
    final receive = ReceivePort();
    late StreamSubscription subscription;
    subscription = receive.listen((_) {
      subscription.cancel();

      if (!completer.isCompleted) {
        completer.complete(true); // Isolate reachable!
        receive.close();
      }
    });

    ping(receive.sendPort, priority: Isolate.immediate);

    Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false); // Isolate timed out!
        subscription.cancel();
        receive.close();
      }
    });

    return completer.future;
  }
}
