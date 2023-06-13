// ignore_for_file: public_member_api_docs

import 'dart:html';

import 'package:js/js_util.dart';
import 'package:sqlite3/wasm.dart';

import 'types.dart';

typedef PostMessage = void Function(Object? msg, [List<Object>? transfer]);

/// Sealed superclass for JavaScript objects exchanged between the UI tab and
/// workers spawned by drift to find a suitable database implementation.
sealed class WasmInitializationMessage {
  WasmInitializationMessage();

  factory WasmInitializationMessage.fromJs(Object jsObject) {
    final type = getProperty<String>(jsObject, 'type');
    final payload = getProperty<Object?>(jsObject, 'payload');

    return switch (type) {
      WorkerError.type => WorkerError.fromJsPayload(payload!),
      ServeDriftDatabase.type => ServeDriftDatabase.fromJsPayload(payload!),
      StartFileSystemServer.type =>
        StartFileSystemServer.fromJsPayload(payload!),
      RequestCompatibilityCheck.type =>
        RequestCompatibilityCheck.fromJsPayload(payload),
      DedicatedWorkerCompatibilityResult.type =>
        DedicatedWorkerCompatibilityResult.fromJsPayload(payload!),
      SharedWorkerCompatibilityResult.type =>
        SharedWorkerCompatibilityResult.fromJsPayload(payload!),
      _ => throw ArgumentError('Unknown type $type'),
    };
  }

  factory WasmInitializationMessage.read(MessageEvent event) {
    // Not using event.data because we don't want the SDK to dartify the raw JS
    // object we're passing around.
    final rawData = getProperty<Object>(event, 'data');
    return WasmInitializationMessage.fromJs(rawData);
  }

  void sendTo(PostMessage sender);

  void sendToWorker(Worker worker) {
    sendTo(worker.postMessage);
  }

  void sendToPort(MessagePort port) {
    sendTo(port.postMessage);
  }

  void sendToClient(DedicatedWorkerGlobalScope worker) {
    sendTo(worker.postMessage);
  }
}

/// A message used by the shared worker to report compatibility results.
///
/// It describes the features available from the shared worker, which the tab
/// can use to infer a desired storage implementation, or whether the shared
/// worker should be used at all.
final class SharedWorkerCompatibilityResult extends WasmInitializationMessage {
  static const type = 'SharedWorkerCompatibilityResult';

  final bool canSpawnDedicatedWorkers;
  final bool dedicatedWorkersCanUseOpfs;
  final bool canUseIndexedDb;

  final bool indexedDbExists;
  final bool opfsExists;

  SharedWorkerCompatibilityResult({
    required this.canSpawnDedicatedWorkers,
    required this.dedicatedWorkersCanUseOpfs,
    required this.canUseIndexedDb,
    required this.indexedDbExists,
    required this.opfsExists,
  });

  factory SharedWorkerCompatibilityResult.fromJsPayload(Object payload) {
    final data = (payload as List).cast<bool>();

    return SharedWorkerCompatibilityResult(
      canSpawnDedicatedWorkers: data[0],
      dedicatedWorkersCanUseOpfs: data[1],
      canUseIndexedDb: data[2],
      indexedDbExists: data[3],
      opfsExists: data[4],
    );
  }

  @override
  void sendTo(PostMessage sender) {
    sender.sendTyped(type, [
      canSpawnDedicatedWorkers,
      dedicatedWorkersCanUseOpfs,
      canUseIndexedDb,
      indexedDbExists,
      opfsExists,
    ]);
  }

  Iterable<MissingBrowserFeature> get missingFeatures sync* {
    if (!canSpawnDedicatedWorkers) {
      yield MissingBrowserFeature.dedicatedWorkersInSharedWorkers;
    } else if (!dedicatedWorkersCanUseOpfs) {
      yield MissingBrowserFeature.fileSystemAccess;
    }
  }
}

/// A message sent by a worker when an error occurred.
final class WorkerError extends WasmInitializationMessage implements Exception {
  static const type = 'Error';

  final String error;

  WorkerError(this.error);

  factory WorkerError.fromJsPayload(Object payload) {
    return WorkerError(payload as String);
  }

  @override
  void sendTo(PostMessage sender) {
    sender.sendTyped(type, error);
  }

  @override
  String toString() {
    return 'Error in worker: $error';
  }
}

/// Instructs a dedicated or shared worker to serve a drift database connection
/// used by the main tab.
final class ServeDriftDatabase extends WasmInitializationMessage {
  static const type = 'ServeDriftDatabase';

  final Uri sqlite3WasmUri;
  final MessagePort port;
  final WasmStorageImplementation storage;
  final String databaseName;
  final MessagePort? initializationPort;

  ServeDriftDatabase({
    required this.sqlite3WasmUri,
    required this.port,
    required this.storage,
    required this.databaseName,
    required this.initializationPort,
  });

  factory ServeDriftDatabase.fromJsPayload(Object payload) {
    return ServeDriftDatabase(
      sqlite3WasmUri: Uri.parse(getProperty(payload, 'sqlite')),
      port: getProperty(payload, 'port'),
      storage: WasmStorageImplementation.values
          .byName(getProperty(payload, 'storage')),
      databaseName: getProperty(payload, 'database'),
      initializationPort: getProperty(payload, 'initPort'),
    );
  }

  @override
  void sendTo(PostMessage sender) {
    final object = newObject<Object>();
    setProperty(object, 'sqlite', sqlite3WasmUri.toString());
    setProperty(object, 'port', port);
    setProperty(object, 'storage', storage.name);
    setProperty(object, 'database', databaseName);
    final initPort = initializationPort;
    setProperty(object, 'initPort', initPort);

    sender.sendTyped(type, object, [
      port,
      if (initPort != null) initPort,
    ]);
  }
}

final class RequestCompatibilityCheck extends WasmInitializationMessage {
  static const type = 'RequestCompatibilityCheck';

  final String databaseName;

  RequestCompatibilityCheck(this.databaseName);

  factory RequestCompatibilityCheck.fromJsPayload(Object? payload) {
    return RequestCompatibilityCheck(payload as String);
  }

  @override
  void sendTo(PostMessage sender) {
    sender.sendTyped(type, databaseName);
  }
}

final class DedicatedWorkerCompatibilityResult
    extends WasmInitializationMessage {
  static const type = 'DedicatedWorkerCompatibilityResult';

  final bool supportsNestedWorkers;
  final bool canAccessOpfs;
  final bool supportsSharedArrayBuffers;
  final bool supportsIndexedDb;

  /// Whether an IndexedDb database under the desired name exists already.
  final bool indexedDbExists;

  /// Whether an OPFS database under the desired name exists already.
  final bool opfsExists;

  DedicatedWorkerCompatibilityResult({
    required this.supportsNestedWorkers,
    required this.canAccessOpfs,
    required this.supportsSharedArrayBuffers,
    required this.supportsIndexedDb,
    required this.indexedDbExists,
    required this.opfsExists,
  });

  factory DedicatedWorkerCompatibilityResult.fromJsPayload(Object payload) {
    return DedicatedWorkerCompatibilityResult(
      supportsNestedWorkers: getProperty(payload, 'supportsNestedWorkers'),
      canAccessOpfs: getProperty(payload, 'canAccessOpfs'),
      supportsSharedArrayBuffers:
          getProperty(payload, 'supportsSharedArrayBuffers'),
      supportsIndexedDb: getProperty(payload, 'supportsIndexedDb'),
      indexedDbExists: getProperty(payload, 'indexedDbExists'),
      opfsExists: getProperty(payload, 'opfsExists'),
    );
  }

  @override
  void sendTo(PostMessage sender) {
    final object = newObject<Object>();

    setProperty(object, 'supportsNestedWorkers', supportsNestedWorkers);
    setProperty(object, 'canAccessOpfs', canAccessOpfs);
    setProperty(object, 'supportsIndexedDb', supportsIndexedDb);
    setProperty(
        object, 'supportsSharedArrayBuffers', supportsSharedArrayBuffers);
    setProperty(object, 'indexedDbExists', indexedDbExists);
    setProperty(object, 'opfsExists', opfsExists);

    sender.sendTyped(type, object);
  }

  Iterable<MissingBrowserFeature> get missingFeatures sync* {
    if (!canAccessOpfs) {
      yield MissingBrowserFeature.fileSystemAccess;
    }
    if (!supportsSharedArrayBuffers) {
      yield MissingBrowserFeature.sharedArrayBuffers;
    }
    if (!supportsIndexedDb) {
      yield MissingBrowserFeature.indexedDb;
    }
  }
}

final class StartFileSystemServer extends WasmInitializationMessage {
  static const type = 'StartFileSystemServer';

  final WorkerOptions sqlite3Options;

  StartFileSystemServer(this.sqlite3Options);

  factory StartFileSystemServer.fromJsPayload(Object payload) {
    return StartFileSystemServer(payload as WorkerOptions);
  }

  @override
  void sendTo(PostMessage sender) {
    sender.sendTyped(type, sqlite3Options);
  }
}

extension on PostMessage {
  void sendTyped(String type, Object? payload, [List<Object>? transfer]) {
    final object = newObject<Object>();
    setProperty(object, 'type', type);
    setProperty(object, 'payload', payload);

    call(object, transfer);
  }
}
