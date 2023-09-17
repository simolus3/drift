// #docregion worker
import 'dart:html';

import 'package:drift/drift.dart';
import 'package:drift/web.dart';
import 'package:drift/web/worker.dart';

void main() {
  // Load sql.js library in the worker
  WorkerGlobalScope.instance.importScripts('sql-wasm.js');

  // Call drift function that will set up this worker
  driftWorkerMain(() {
    return WebDatabase.withStorage(DriftWebStorage.indexedDb('worker',
        migrateFromLocalStorage: false, inWebWorker: true));
  });
}
// #enddocregion worker

// #docregion client
DatabaseConnection connectToWorker() {
  return DatabaseConnection.delayed(connectToDriftWorker(
    'worker.dart.js',
    // Note that SharedWorkers may not be available on all browsers and platforms.
    mode: DriftWorkerMode.shared,
  ));
}
// #enddocregion client
