/// This file is responsible for opening a suitable WASM sqlite3 database based
/// on the features available in the browsing context we're in.
///
/// The main challenge of hosting a sqlite3 database in the browser is the
/// implementation of a persistence solution. Being a C library, sqlite3 expects
/// synchronous access to a file system, which is tricky to implement with
/// asynchronous
library;

import 'dart:async';
import 'dart:html';

import 'package:async/async.dart';
import 'package:drift/wasm.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'wasm_setup/protocol.dart';

@JS()
external bool get crossOriginIsolated;

bool get supportsSharedWorkers => hasProperty(globalThis, 'SharedWorker');

Future<WasmDatabaseResult> openWasmDatabase({
  required Uri sqlite3WasmUri,
  required Uri driftWorkerUri,
  required String databaseName,
}) async {
  // First, let's see if we can spawn dedicated workers in shared workers, which
  // would enable us to efficiently share a OPFS database.
  if (supportsSharedWorkers) {
    final sharedWorker =
        SharedWorker(driftWorkerUri.toString(), 'drift worker');
    final port = sharedWorker.port!;

    final sharedMessages =
        StreamQueue(port.onMessage.map(WasmInitializationMessage.fromJs));

    // First, the shared worker will tell us which features it supports.
    final sharedFeatures = await sharedMessages.next as SharedWorkerStatus;
  } else {
    // If we don't support shared workers, we might still have support for
    // OPFS in dedicated workers.
    final dedicatedWorker = Worker(driftWorkerUri.toString());
    DedicatedWorkerCompatibilityCheck().sendToWorker(dedicatedWorker);

    final workerMessages = StreamQueue(
        dedicatedWorker.onMessage.map(WasmInitializationMessage.fromJs));

    final status =
        await workerMessages.next as DedicatedWorkerCompatibilityResult;
  }

  throw 'todo';
}
