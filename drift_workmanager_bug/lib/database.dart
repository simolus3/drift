import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

const driftPortName = 'drift.shared.db.port';

Future<DriftIsolate> ensureDriftIsolate() async {
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'filename.sqlite');

  var driftPort = IsolateNameServer.lookupPortByName("somePortName");
  if (driftPort == null) {
    final receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(receivePort.sendPort, driftPortName);
    await Isolate.spawn(
        _startBackground, _IsolateStartRequest(receivePort.sendPort, path));

    final firstMessage = await receivePort.first;

    driftPort = firstMessage as SendPort;
  }

  return DriftIsolate.fromConnectPort(driftPort);
}

void _startBackground(_IsolateStartRequest request) {
  final driftIsolate =
      DriftIsolate.inCurrent(() => DatabaseConnection(LazyDatabase(() async {
            final file = File(request.targetPath);
            return NativeDatabase(file, logStatements: false, setup: (rawDb) {
              rawDb.execute("PRAGMA key = 'secretPassword';");
            });
          })));

  // inform the starting isolate about this, so that it can call .connect()
  request.sendDriftIsolate.send(driftIsolate.connectPort);
}

class _IsolateStartRequest {
  final SendPort sendDriftIsolate;
  final String targetPath;

  _IsolateStartRequest(this.sendDriftIsolate, this.targetPath);
}
