/// This file is responsible for opening a suitable WASM sqlite3 database based
/// on the features available in the browsing context we're in.
///
/// The main challenge of hosting a sqlite3 database in the browser is the
/// implementation of a persistence solution. Being a C library, sqlite3 expects
/// synchronous access to a file system, which is tricky to implement with
/// asynchronous
// ignore_for_file: public_member_api_docs
@internal
library;

import 'dart:async';
import 'dart:html';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/wasm.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3/wasm.dart';

import 'channel.dart';
import 'wasm_setup/protocol.dart';

/// Whether the `crossOriginIsolated` JavaScript property is true in the current
/// context.
@JS()
external bool get crossOriginIsolated;

/// Whether shared workers can be constructed in the current context.
bool get supportsSharedWorkers => hasProperty(globalThis, 'SharedWorker');

/// Whether dedicated workers can be constructed in the current context.
bool get supportsWorkers => hasProperty(globalThis, 'Worker');

class WasmDatabaseOpener {
  final Uri sqlite3WasmUri;
  final Uri driftWorkerUri;
  final String databaseName;

  final Set<MissingBrowserFeature> missingFeatures = {};
  final List<WasmStorageImplementation> availableImplementations = [
    WasmStorageImplementation.inMemory,
  ];

  bool _existsInIndexedDb = false;
  bool _existsInOpfs = false;

  MessagePort? _sharedWorker;
  Worker? _dedicatedWorker;

  WasmDatabaseOpener({
    required this.sqlite3WasmUri,
    required this.driftWorkerUri,
    required this.databaseName,
  });

  Future<void> probe() async {
    await _probeShared();
    await _probeDedicated();
  }

  Future<WasmDatabaseResult> open() async {
    await probe();

    // If we have an existing database in storage, we want to keep using that
    // format to avoid data loss (e.g. after a browser update that enables a
    // otherwise preferred storage implementation). In the future, we might want
    // to consider migrating between storage implementations as well.
    if (_existsInIndexedDb) {
      availableImplementations.removeWhere((element) =>
          element != WasmStorageImplementation.sharedIndexedDb &&
          element != WasmStorageImplementation.unsafeIndexedDb);
    } else if (_existsInOpfs) {
      availableImplementations.removeWhere((element) =>
          element != WasmStorageImplementation.opfsShared &&
          element != WasmStorageImplementation.opfsLocks);
    }

    // Enum values are ordered by preferrability, so just pick the best option
    // left.
    availableImplementations.sortBy<num>((element) => element.index);
    return await _connect(availableImplementations.firstOrNull ??
        WasmStorageImplementation.inMemory);
  }

  /// Opens a database with the given [storage] implementation, bypassing the
  /// feature detection. Must be called after [probe].
  Future<WasmDatabaseResult> openWith(WasmStorageImplementation storage) async {
    return await _connect(storage);
  }

  void _closeSharedWorker() {
    _sharedWorker?.close();
  }

  void _closeDedicatedWorker() {
    _dedicatedWorker?.terminate();
  }

  Future<WasmDatabaseResult> _connect(WasmStorageImplementation storage) async {
    final channel = MessageChannel();
    final local = channel.port1.channel();
    final message = ServeDriftDatabase(
      sqlite3WasmUri: sqlite3WasmUri,
      port: channel.port2,
      storage: storage,
      databaseName: databaseName,
    );

    switch (storage) {
      case WasmStorageImplementation.opfsShared:
      case WasmStorageImplementation.sharedIndexedDb:
        message.sendToPort(_sharedWorker!);
        // These are handled by the shared worker, so we can close the dedicated
        // worker used for feature detection.
        _closeDedicatedWorker();
      case WasmStorageImplementation.opfsLocks:
      case WasmStorageImplementation.unsafeIndexedDb:
        _closeSharedWorker();
        message.sendToWorker(_dedicatedWorker!);
      case WasmStorageImplementation.inMemory:
        // Nothing works on this browser, so we'll fall back to an in-memory
        // database.
        final sqlite3 = await WasmSqlite3.loadFromUrl(sqlite3WasmUri);
        sqlite3.registerVirtualFileSystem(InMemoryFileSystem());

        return WasmDatabaseResult(
          DatabaseConnection(
            WasmDatabase(sqlite3: sqlite3, path: '/database'),
          ),
          WasmStorageImplementation.inMemory,
          missingFeatures,
        );
    }

    final connection = await connectToRemoteAndInitialize(local);
    return WasmDatabaseResult(connection, storage, missingFeatures);
  }

  Future<void> _probeShared() async {
    if (supportsSharedWorkers) {
      final sharedWorker =
          SharedWorker(driftWorkerUri.toString(), 'drift worker');
      final port = _sharedWorker = sharedWorker.port!;

      final sharedMessages =
          StreamQueue(port.onMessage.map(WasmInitializationMessage.read));

      // First, the shared worker will tell us which features it supports.
      final sharedFeatures =
          await sharedMessages.nextNoError as SharedWorkerStatus;
      await sharedMessages.cancel();
      missingFeatures.addAll(sharedFeatures.missingFeatures);

      // Prefer to use the shared worker to host the database if it supports the
      // necessary APIs.
      if (sharedFeatures.canSpawnDedicatedWorkers &&
          sharedFeatures.dedicatedWorkersCanUseOpfs) {
        availableImplementations.add(WasmStorageImplementation.opfsShared);
      }
      if (sharedFeatures.canUseIndexedDb) {
        availableImplementations.add(WasmStorageImplementation.sharedIndexedDb);
      }
    } else {
      missingFeatures.add(MissingBrowserFeature.sharedWorkers);
    }
  }

  Future<void> _probeDedicated() async {
    if (supportsWorkers) {
      final dedicatedWorker = Worker(driftWorkerUri.toString());
      DedicatedWorkerCompatibilityCheck(databaseName)
          .sendToWorker(dedicatedWorker);

      final workerMessages = StreamQueue(
          dedicatedWorker.onMessage.map(WasmInitializationMessage.read));

      final status = await workerMessages.nextNoError
          as DedicatedWorkerCompatibilityResult;
      missingFeatures.addAll(status.missingFeatures);

      _existsInOpfs = status.opfsExists;
      _existsInIndexedDb = status.indexedDbExists;

      if (status.supportsNestedWorkers &&
          status.canAccessOpfs &&
          status.supportsSharedArrayBuffers) {
        availableImplementations.add(WasmStorageImplementation.opfsLocks);
      }

      if (status.supportsIndexedDb) {
        availableImplementations.add(WasmStorageImplementation.unsafeIndexedDb);
      }
    } else {
      missingFeatures.add(MissingBrowserFeature.dedicatedWorkers);
    }
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
