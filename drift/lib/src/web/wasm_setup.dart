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
import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:drift/wasm.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3/wasm.dart';

import 'broadcast_stream_queries.dart';
import 'channel.dart';
import 'wasm_setup/shared.dart';
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

  final String? databaseName;

  final Set<MissingBrowserFeature> missingFeatures = {};
  final List<WasmStorageImplementation> availableImplementations = [
    WasmStorageImplementation.inMemory,
  ];
  final Set<ExistingDatabase> existingDatabases = {};

  _DriftWorker? _sharedWorker, _dedicatedWorker;

  WasmDatabaseOpener(
    this.sqlite3WasmUri,
    this.driftWorkerUri,
    this.databaseName,
  );

  RequestCompatibilityCheck _createCompatibilityCheck() {
    return RequestCompatibilityCheck(databaseName ?? 'driftCompatibilityCheck');
  }

  void _handleCompatibilityResult(CompatibilityResult result) {
    missingFeatures.addAll(result.missingFeatures);

    final databaseName = this.databaseName;

    // Note that existingDatabases are only sent from workers shipped with drift
    // 2.11 or later. Later drift versions need to be able to talk to newer
    // workers though.
    if (result.existingDatabases.isNotEmpty) {
      existingDatabases.addAll(result.existingDatabases);
    }

    if (databaseName != null) {
      // If this opener has been created for WasmDatabase.open, we have a
      // database name and can interpret the opfsExists and indexedDbExists
      // fields we're getting from older workers accordingly.
      if (result.opfsExists) {
        existingDatabases.add((WebStorageApi.opfs, databaseName));
      }
      if (result.indexedDbExists) {
        existingDatabases.add((WebStorageApi.indexedDb, databaseName));
      }
    }
  }

  Future<WasmProbeResult> probe() async {
    try {
      await _probeShared();
    } on Object {
      _sharedWorker?.close();
      _sharedWorker = null;
    }
    try {
      await _probeDedicated();
    } on Object {
      _dedicatedWorker?.close();
      _dedicatedWorker = null;
    }

    return _ProbeResult(availableImplementations, existingDatabases.toList(),
        missingFeatures, this);
  }

  Future<void> _probeDedicated() async {
    if (supportsWorkers) {
      final dedicatedWorker = _dedicatedWorker =
          _DriftWorker.dedicated(Worker(driftWorkerUri.toString()));
      _createCompatibilityCheck().sendTo(dedicatedWorker.send);

      final status = await dedicatedWorker.workerMessages.nextNoError
          as DedicatedWorkerCompatibilityResult;

      _handleCompatibilityResult(status);

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

  Future<void> _probeShared() async {
    if (supportsSharedWorkers) {
      final sharedWorker =
          SharedWorker(driftWorkerUri.toString(), 'drift worker');
      final port = sharedWorker.port!;
      final shared = _sharedWorker = _DriftWorker.shared(sharedWorker, port);

      // First, the shared worker will tell us which features it supports.
      _createCompatibilityCheck().sendToPort(port);
      final sharedFeatures = await shared.workerMessages.nextNoError
          as SharedWorkerCompatibilityResult;

      _handleCompatibilityResult(sharedFeatures);

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
}

final class _DriftWorker {
  final AbstractWorker worker;

  /// The message port to communicate with the worker, if it's a shared worker.
  final MessagePort? portForShared;

  final StreamQueue<WasmInitializationMessage> workerMessages;

  _DriftWorker.dedicated(Worker this.worker)
      : portForShared = null,
        workerMessages =
            StreamQueue(_readMessages(worker.onMessage, worker.onError));

  _DriftWorker.shared(SharedWorker this.worker, this.portForShared)
      : workerMessages =
            StreamQueue(_readMessages(worker.port!.onMessage, worker.onError));

  void send(Object? msg, [List<Object>? transfer]) {
    switch (worker) {
      case final Worker worker:
        worker.postMessage(msg, transfer);
      case SharedWorker():
        portForShared!.postMessage(msg, transfer);
    }
  }

  void close() {
    workerMessages.cancel();

    switch (worker) {
      case final Worker dedicated:
        dedicated.terminate();
      case SharedWorker():
        portForShared!.close();
    }
  }
}

final class _ProbeResult implements WasmProbeResult {
  @override
  final List<WasmStorageImplementation> availableStorages;

  @override
  final List<ExistingDatabase> existingDatabases;

  @override
  final Set<MissingBrowserFeature> missingFeatures;

  final WasmDatabaseOpener opener;

  _ProbeResult(
    this.availableStorages,
    this.existingDatabases,
    this.missingFeatures,
    this.opener,
  );

  @override
  Future<DatabaseConnection> open(
    WasmStorageImplementation implementation,
    String name, {
    FutureOr<Uint8List?> Function()? initializeDatabase,
    WasmDatabaseSetup? localSetup,
  }) async {
    final channel = MessageChannel();
    final initializer = initializeDatabase;
    final initChannel = initializer != null ? MessageChannel() : null;
    final local = channel.port1.channel();

    final message = ServeDriftDatabase(
      sqlite3WasmUri: opener.sqlite3WasmUri,
      port: channel.port2,
      storage: implementation,
      databaseName: name,
      initializationPort: initChannel?.port2,
    );

    final sharedWorker = opener._sharedWorker;
    final dedicatedWorker = opener._dedicatedWorker;

    switch (implementation) {
      case WasmStorageImplementation.opfsShared:
      case WasmStorageImplementation.sharedIndexedDb:
        // Forward connection request to shared worker.
        message.sendTo(sharedWorker!.send);
      case WasmStorageImplementation.opfsLocks:
      case WasmStorageImplementation.unsafeIndexedDb:
        if (dedicatedWorker != null) {
          message.sendTo(dedicatedWorker.send);
        } else {
          // Workers seem to be broken, but we don't need them with this storage
          // mode.
          return _hostDatabaseLocally(
              implementation,
              await IndexedDbFileSystem.open(dbName: name),
              initializeDatabase,
              localSetup);
        }
      case WasmStorageImplementation.inMemory:
        // Nothing works on this browser, so we'll fall back to an in-memory
        // database.
        return _hostDatabaseLocally(implementation, InMemoryFileSystem(),
            initializeDatabase, localSetup);
    }

    initChannel?.port1.onMessage.listen((event) async {
      // The worker hosting the database is asking for the initial blob because
      // the database doesn't exist.
      Uint8List? result;
      try {
        result = await initializer?.call();
      } finally {
        initChannel.port1
          ..postMessage(result, [if (result != null) result.buffer])
          ..close();
      }
    });

    var connection = await connectToRemoteAndInitialize(local);
    if (implementation == WasmStorageImplementation.opfsLocks) {
      // We want stream queries to update for writes in other tabs. For the
      // implementations backed by a shared worker, the worker takes care of
      // that.
      // We don't enable this for unsafeIndexedDb since that implementation
      // generally doesn't support a database being accessed concurrently.
      // With the in-memory implementation, we have a tab-local database and
      // can't share anything.
      if (BroadcastStreamQueryStore.supported) {
        connection = DatabaseConnection(
          connection.executor,
          connectionData: connection.connectionData,
          streamQueries: BroadcastStreamQueryStore(name),
        );
      }
    }

    return connection;
  }

  /// Returns a database connection that doesn't use web workers.
  Future<DatabaseConnection> _hostDatabaseLocally(
    WasmStorageImplementation storage,
    VirtualFileSystem vfs,
    FutureOr<Uint8List?> Function()? initializer,
    WasmDatabaseSetup? setup,
  ) async {
    final database = await DriftServerController(setup).openConnection(
      sqlite3WasmUri: opener.sqlite3WasmUri,
      databaseName: 'database',
      storage: storage,
      initializer: initializer,
    );

    return DatabaseConnection(database);
  }

  @override
  Future<void> deleteDatabase(ExistingDatabase database) async {
    switch (database.$1) {
      case WebStorageApi.indexedDb:
        await deleteDatabaseInIndexedDb(database.$2);
      case WebStorageApi.opfs:
        final dedicated = opener._dedicatedWorker;
        if (dedicated != null) {
          DeleteDatabase(database).sendTo(dedicated.send);

          await dedicated.workerMessages.nextNoError;
        } else {
          throw StateError(
              'No dedicated worker available to delete OPFS database');
        }
    }
  }
}

Stream<WasmInitializationMessage> _readMessages(
    Stream<MessageEvent> messages, Stream<Event> errors) {
  final mappedMessages = messages.map(WasmInitializationMessage.read);

  return Stream.multi((listener) {
    StreamSubscription? subscription;

    void stop() {
      subscription = null;
      listener.closeSync();
    }

    subscription = mappedMessages.listen(
      listener.addSync,
      onError: listener.addErrorSync,
      onDone: stop,
    );

    errors.first.then((value) {
      if (subscription != null) {
        listener
            .addSync(WorkerError('Worker emitted an error through onError.'));
      }
    });

    listener
      ..onCancel = () {
        subscription?.cancel();
        subscription = null;
      }
      ..onPause = subscription!.pause
      ..onResume = subscription!.resume;
  });
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
