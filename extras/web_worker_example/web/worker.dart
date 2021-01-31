import 'dart:html';

import 'package:moor/moor.dart';
import 'package:moor/moor_web.dart';
import 'package:moor/remote.dart';

void main() {
  final self = SharedWorkerGlobalScope.instance;
  self.importScripts('sql-wasm.js');

  final db = WebDatabase.withStorage(MoorWebStorage.indexedDb('worker',
      migrateFromLocalStorage: false, inWebWorker: true));
  final server = MoorServer(DatabaseConnection.fromExecutor(db));

  self.onConnect.listen((event) {
    final msg = event as MessageEvent;
    server.serve(msg.ports.first.channel());
  });
}
