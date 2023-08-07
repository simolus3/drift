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

import 'broadcast_stream_queries.dart';
import 'channel.dart';
import 'wasm_setup/protocol.dart';
import 'wasm_setup/shared.dart';

/// Whether the `crossOriginIsolated` JavaScript property is true in the current
/// context.
@JS()
external bool get crossOriginIsolated;

/// Whether shared workers can be constructed in the current context.
bool get supportsSharedWorkers => hasProperty(globalThis, 'SharedWorker');

/// Whether dedicated workers can be constructed in the current context.
bool get supportsWorkers => hasProperty(globalThis, 'Worker');

class WasmDatabaseOpener2 {
  final Uri sqlite3WasmUri;
  final Uri driftWorkerUri;

  final String? databaseName;

  final Set<MissingBrowserFeature> missingFeatures = {};
  final List<WasmStorageImplementation> availableImplementations = [
    WasmStorageImplementation.inMemory,
  ];
  final Set<(DatabaseLocation, String)> existingDatabases = {};

  MessagePort? _sharedWorker;
  Worker? _dedicatedWorker;

  WasmDatabaseOpener2(
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
        existingDatabases.add((DatabaseLocation.opfs, databaseName));
      }
      if (result.indexedDbExists) {
        existingDatabases.add((DatabaseLocation.indexedDb, databaseName));
      }
    }
  }

  Future<WasmProbeResult> probe() async {
    await _probeDedicated();
  }

  Future<void> _probeDedicated() async {
    if (supportsWorkers) {
      final dedicatedWorker =
          _dedicatedWorker = Worker(driftWorkerUri.toString());
      _createCompatibilityCheck().sendToWorker(dedicatedWorker);

      final workerMessages = StreamQueue(
          _readMessages(dedicatedWorker.onMessage, dedicatedWorker.onError));

      final status = await workerMessages.nextNoError
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
}

final class _ProbeResult extends WasmProbeResult {
  @override
  final List<WasmStorageImplementation> availableStorages;

  @override
  final List<(DatabaseLocation, String)> existingDatabases;

  @override
  final Set<MissingBrowserFeature> missingFeatures;

  final WasmDatabaseOpener2 opener;

  _ProbeResult(
    this.availableStorages,
    this.existingDatabases,
    this.missingFeatures,
    this.opener,
  );

  @override
  Future<DatabaseConnection> open(
      WasmStorageImplementation implementation, String name,
      {FutureOr<Uint8List?> Function()? initializeDatabase}) async {
    // TODO: implement open
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDatabase(
      DatabaseLocation implementation, String name) async {
    // TODO: implement deleteDatabase
    throw UnimplementedError();
  }
}

class WasmDatabaseOpener {
  final Uri sqlite3WasmUri;
  final Uri driftWorkerUri;
  final String databaseName;
  FutureOr<Uint8List?> Function()? initializeDatabase;

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
    this.initializeDatabase,
  });

  Future<void> probe() async {
    try {
      await _probeShared();
    } on Object {
      _sharedWorker?.close();
      _sharedWorker = null;
    }
    try {
      await _probeDedicated();
    } on Object {
      _dedicatedWorker?.terminate();
      _dedicatedWorker = null;
    }

    if (_dedicatedWorker == null) {
      // Something is wrong with web workers, let's see if we can get things
      // running without a worker.
      if (await checkIndexedDbSupport()) {
        availableImplementations.add(WasmStorageImplementation.unsafeIndexedDb);
        _existsInIndexedDb = await checkIndexedDbExists(databaseName);
      }
    }
  }

  Future<WasmDatabaseResult> open() async {
    await probe();

    // If we have an existing database in storage, we want to keep using that
    // format to avoid data loss (e.g. after a browser update that enables a
    // otherwise preferred storage implementation). In the future, we might want
    // to consider migrating between storage implementations as well.
    if (_existsInIndexedDb &&
        (availableImplementations
                .contains(WasmStorageImplementation.sharedIndexedDb) ||
            availableImplementations
                .contains(WasmStorageImplementation.unsafeIndexedDb))) {
      availableImplementations.removeWhere((element) =>
          element != WasmStorageImplementation.sharedIndexedDb &&
          element != WasmStorageImplementation.unsafeIndexedDb);
    } else if (_existsInOpfs &&
        (availableImplementations
                .contains(WasmStorageImplementation.opfsShared) ||
            availableImplementatioobjectns
                .contains(WasmStorageImplementation.opfsLocks))) {
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

  Future<WasmDatabaseResult> _connect(WasmStorageImplementation storage) async {
    final channel = MessageChannel();
    final initializer = initializeDatabase;
    final initChannel = initializer != null ? MessageChannel() : null;
    final local = channel.port1.channel();

    final message = ServeDriftDatabase(
      sqlite3WasmUri: sqlite3WasmUri,
      port: channel.port2,
      storage: storage,
      databaseName: databaseName,
      initializationPort: initChannel?.port2,
    );

    final sharedWorker = _sharedWorker;
    final dedicatedWorker = _dedicatedWorker;

    switch (storage) {
      case WasmStorageImplementation.opfsShared:
      case WasmStorageImplementation.sharedIndexedDb:
        // These are handled by the shared worker, so we can close the dedicated
        // worker used for feature detection.
        dedicatedWorker?.terminate();
        message.sendToPort(sharedWorker!);
      case WasmStorageImplementation.opfsLocks:
      case WasmStorageImplementation.unsafeIndexedDb:
        sharedWorker?.close();

        if (dedicatedWorker != null) {
          message.sendToWorker(dedicatedWorker);
        } else {
          // Workers seem to be broken, but we don't need them with this storage
          // mode.
          return _hostDatabaseLocally(
              storage, await IndexedDbFileSystem.open(dbName: databaseName));
        }

      case WasmStorageImplementation.inMemory:
        // Nothing works on this browser, so we'll fall back to an in-memory
        // database.
        return _hostDatabaseLocally(storage, InMemoryFileSystem());
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
    if (storage == WasmStorageImplementation.opfsLocks) {
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
          streamQueries: BroadcastStreamQueryStore(databaseName),
        );
      }
    }

    return WasmDatabaseResult(connection, storage, missingFeatures);
  }

  /// Returns a database connection that doesn't use web workers.
  Future<WasmDatabaseResult> _hostDatabaseLocally(
      WasmStorageImplementation storage, VirtualFileSystem vfs) async {
    final initializer = initializeDatabase;

    final sqlite3 = await WasmSqlite3.loadFromUrl(sqlite3WasmUri);
    sqlite3.registerVirtualFileSystem(vfs);

    if (initializer != null) {
      final blob = await initializer();
      if (blob != null) {
        final (file: file, outFlags: _) =
            vfs.xOpen(Sqlite3Filename('/database'), SqlFlag.SQLITE_OPEN_CREATE);
        file
          ..xWrite(blob, 0)
          ..xClose();
      }
    }

    return WasmDatabaseResult(
      DatabaseConnection(
        WasmDatabase(sqlite3: sqlite3, path: '/database'),
      ),
      storage,
      missingFeatures,
    );
  }

  Future<void> _probeShared() async {
    if (supportsSharedWorkers) {
      final sharedWorker =
          SharedWorker(driftWorkerUri.toString(), 'drift worker');
      final port = _sharedWorker = sharedWorker.port!;

      final sharedMessages =
          StreamQueue(_readMessages(port.onMessage, sharedWorker.onError));

      // First, the shared worker will tell us which features it supports.
      RequestCompatibilityCheck(databaseName).sendToPort(port);
      final sharedFeatures =
          await sharedMessages.nextNoError as SharedWorkerCompatibilityResult;
      await sharedMessages.cancel();
      missingFeatures.addAll(sharedFeatures.missingFeatures);

      _existsInOpfs |= sharedFeatures.opfsExists;
      _existsInIndexedDb |= sharedFeatures.indexedDbExists;

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
      final dedicatedWorker =
          _dedicatedWorker = Worker(driftWorkerUri.toString());
      RequestCompatibilityCheck(databaseName).sendToWorker(dedicatedWorker);

      final workerMessages = StreamQueue(
          _readMessages(dedicatedWorker.onMessage, dedicatedWorker.onError));

      final status = await workerMessages.nextNoError
          as DedicatedWorkerCompatibilityResult;
      missingFeatures.addAll(status.missingFeatures);

      _existsInOpfs |= status.opfsExists;
      _existsInIndexedDb |= status.indexedDbExists;

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
