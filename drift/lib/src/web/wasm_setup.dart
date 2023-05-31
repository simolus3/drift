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
import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/wasm.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:sqlite3/wasm.dart';

import 'channel.dart';
import 'wasm_setup/protocol.dart';

/// Whether the `crossOriginIsolated` JavaScript property is true in the current
/// context.
@JS()
external bool get crossOriginIsolated;

/// Whether shared workers can be constructed in the current context.
bool get supportsSharedWorkers => hasProperty(globalThis, 'SharedWorker');

Future<WasmDatabaseResult> openWasmDatabase({
  required Uri sqlite3WasmUri,
  required Uri driftWorkerUri,
  required String databaseName,
}) async {
  final missingFeatures = <MissingBrowserFeature>{};

  Future<WasmDatabaseResult> connect(WasmStorageImplementation impl,
      void Function(WasmInitializationMessage) send) async {
    final channel = MessageChannel();
    final local = channel.port1.channel();
    final message = ServeDriftDatabase(
      sqlite3WasmUri: sqlite3WasmUri,
      port: channel.port2,
      storage: impl,
      databaseName: databaseName,
    );
    send(message);

    final connection = await connectToRemoteAndInitialize(local);
    return WasmDatabaseResult(connection, impl, missingFeatures);
  }

  // First, let's see if we can spawn dedicated workers in shared workers, which
  // would enable us to efficiently share a OPFS database.
  if (supportsSharedWorkers) {
    final sharedWorker =
        SharedWorker(driftWorkerUri.toString(), 'drift worker');
    final port = sharedWorker.port!;

    final sharedMessages =
        StreamQueue(port.onMessage.map(WasmInitializationMessage.read));

    // First, the shared worker will tell us which features it supports.
    final sharedFeatures =
        await sharedMessages.nextNoError as SharedWorkerStatus;
    missingFeatures.addAll(sharedFeatures.missingFeatures);

    // Can we use the shared OPFS implementation?
    if (sharedFeatures.canSpawnDedicatedWorkers &&
        sharedFeatures.dedicatedWorkersCanUseOpfs) {
      return connect(
          WasmStorageImplementation.opfsShared, (msg) => msg.sendToPort(port));
    } else if (sharedFeatures.canUseIndexedDb) {
      return connect(WasmStorageImplementation.sharedIndexedDb,
          (msg) => msg.sendToPort(port));
    } else {
      await sharedMessages.cancel();
      port.close();
    }
  } else {
    missingFeatures.add(MissingBrowserFeature.sharedWorkers);
  }

  final dedicatedWorker = Worker(driftWorkerUri.toString());
  DedicatedWorkerCompatibilityCheck().sendToWorker(dedicatedWorker);

  final workerMessages = StreamQueue(
      dedicatedWorker.onMessage.map(WasmInitializationMessage.read));

  final status =
      await workerMessages.nextNoError as DedicatedWorkerCompatibilityResult;
  missingFeatures.addAll(status.missingFeatures);

  if (status.supportsNestedWorkers &&
      status.canAccessOpfs &&
      status.supportsSharedArrayBuffers) {
    return connect(WasmStorageImplementation.opfsLocks,
        (msg) => msg.sendToWorker(dedicatedWorker));
  } else if (status.supportsIndexedDb) {
    return connect(WasmStorageImplementation.unsafeIndexedDb,
        (msg) => msg.sendToWorker(dedicatedWorker));
  } else {
    // Nothing works on this browser, so we'll fall back to an in-memory
    // database.
    final sqlite3 = await WasmSqlite3.loadFromUrl(sqlite3WasmUri);
    sqlite3.registerVirtualFileSystem(InMemoryFileSystem());

    return WasmDatabaseResult(
      DatabaseConnection(
        WasmDatabase(sqlite3: sqlite3, path: '/app.db'),
      ),
      WasmStorageImplementation.inMemory,
      missingFeatures,
    );
  }
}

extension on StreamQueue<WasmInitializationMessage> {
  Future<WasmInitializationMessage> get nextNoError {
    return next.then((value) {
      if (value is WorkerError) {
        throw value;
      }

      return value;
    });
  }
}
