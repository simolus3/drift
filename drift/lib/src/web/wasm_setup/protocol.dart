// ignore_for_file: public_member_api_docs

import 'dart:html';

import 'package:drift/wasm.dart';
import 'package:js/js_util.dart';
import 'package:sqlite3/wasm.dart';

typedef _PostMessage = void Function(Object? msg, [List<Object>? transfer]);

/// Sealed superclass for JavaScript objects exchanged between the UI tab and
/// workers spawned by drift to find a suitable database implementation.
sealed class WasmInitializationMessage {
  WasmInitializationMessage();

  factory WasmInitializationMessage.fromJs(Object jsObject) {
    final type = getProperty<String>(jsObject, 'type');
    final payload = getProperty<String>(jsObject, 'payload');

    return switch (type) {
      SharedWorkerStatus.type => SharedWorkerStatus.fromJsPayload(payload),
      WorkerError.type => WorkerError.fromJsPayload(payload),
      ServeDriftDatabase.type => ServeDriftDatabase.fromJsPayload(payload),
      StartFileSystemServer.type =>
        StartFileSystemServer.fromJsPayload(payload),
      DedicatedWorkerCompatibilityCheck.type =>
        DedicatedWorkerCompatibilityCheck.fromJsPayload(payload),
      DedicatedWorkerCompatibilityResult.type =>
        DedicatedWorkerCompatibilityResult.fromJsPayload(payload),
      _ => throw ArgumentError('Unknown type $type'),
    };
  }

  factory WasmInitializationMessage.read(MessageEvent event) {
    // Not using event.data because we don't want the SDK to dartify the raw JS
    // object we're passing around.
    final rawData = getProperty<Object>(event, 'data');
    return WasmInitializationMessage.fromJs(rawData);
  }

  void _send(_PostMessage sender);

  void sendToWorker(Worker worker) {
    _send(worker.postMessage);
  }

  void sendToPort(MessagePort port) {
    _send(port.postMessage);
  }

  void sendToClient(DedicatedWorkerGlobalScope worker) {
    _send(worker.postMessage);
  }
}

/// A message sent by the shared worker to a connecting tab. It describes the
/// features available from the shared worker, which the tab can use to infer
/// a desired storage implementation, or whether the shared worker should be
/// used at all.
final class SharedWorkerStatus extends WasmInitializationMessage {
  static const type = 'SharedWorkerStatus';

  final bool canSpawnDedicatedWorkers;
  final bool dedicatedWorkersCanUseOpfs;

  SharedWorkerStatus({
    required this.canSpawnDedicatedWorkers,
    required this.dedicatedWorkersCanUseOpfs,
  });

  factory SharedWorkerStatus.fromJsPayload(Object payload) {
    final data = (payload as List).cast<bool>();

    return SharedWorkerStatus(
      canSpawnDedicatedWorkers: data[0],
      dedicatedWorkersCanUseOpfs: data[1],
    );
  }

  @override
  void _send(_PostMessage sender) {
    sender.sendTyped(type, [
      canSpawnDedicatedWorkers,
      dedicatedWorkersCanUseOpfs,
    ]);
  }

  Iterable<MissingBrowserFeature> get missingFeatures sync* {
    if (!canSpawnDedicatedWorkers) {
      yield MissingBrowserFeature.dedicatedWorkersInSharedWorkers;
    }

    if (!dedicatedWorkersCanUseOpfs) {
      yield MissingBrowserFeature.fileSystemAccess;
    }
  }
}

/// A message sent by a worker when an error occurred.
final class WorkerError extends WasmInitializationMessage {
  static const type = 'Error';

  final String error;

  WorkerError(this.error);

  factory WorkerError.fromJsPayload(Object payload) {
    return WorkerError(payload as String);
  }

  @override
  void _send(_PostMessage sender) {
    sender.sendTyped(type, error);
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

  ServeDriftDatabase({
    required this.sqlite3WasmUri,
    required this.port,
    required this.storage,
    required this.databaseName,
  });

  factory ServeDriftDatabase.fromJsPayload(Object payload) {
    return ServeDriftDatabase(
      sqlite3WasmUri: Uri.parse(getProperty(payload, 'sqlite')),
      port: getProperty(payload, 'port'),
      storage: WasmStorageImplementation.values
          .byName(getProperty(payload, 'storage')),
      databaseName: getProperty(payload, 'database'),
    );
  }

  @override
  void _send(_PostMessage sender) {
    final object = newObject<Object>();
    setProperty(object, 'sqlite', sqlite3WasmUri.toString());
    setProperty(object, 'port', port);
    setProperty(object, 'storage', storage.name);
    setProperty(object, 'database', databaseName);

    sender.sendTyped(type, object, [port]);
  }
}

final class DedicatedWorkerCompatibilityCheck
    extends WasmInitializationMessage {
  static const type = 'DedicatedWorkerCompatibilityCheck';

  DedicatedWorkerCompatibilityCheck();

  factory DedicatedWorkerCompatibilityCheck.fromJsPayload(Object payload) {
    return DedicatedWorkerCompatibilityCheck();
  }

  @override
  void _send(_PostMessage sender) {
    sender.sendTyped(type, null);
  }
}

final class DedicatedWorkerCompatibilityResult
    extends WasmInitializationMessage {
  static const type = 'DedicatedWorkerCompatibilityResult';

  final bool supportsNestedWorkers;
  final bool canAccessOpfs;
  final bool supportsSharedArrayBuffers;
  final bool supportsIndexedDb;

  DedicatedWorkerCompatibilityResult({
    required this.supportsNestedWorkers,
    required this.canAccessOpfs,
    required this.supportsSharedArrayBuffers,
    required this.supportsIndexedDb,
  });

  factory DedicatedWorkerCompatibilityResult.fromJsPayload(Object payload) {
    return DedicatedWorkerCompatibilityResult(
      supportsNestedWorkers: getProperty(payload, 'supportsNestedWorkers'),
      canAccessOpfs: getProperty(payload, 'canAccessOpfs'),
      supportsSharedArrayBuffers:
          getProperty(payload, 'supportsSharedArrayBuffers'),
      supportsIndexedDb: getProperty(payload, 'supportsIndexedDb'),
    );
  }

  @override
  void _send(_PostMessage sender) {
    final object = newObject<Object>();

    setProperty(object, 'supportsNestedWorkers', supportsNestedWorkers);
    setProperty(object, 'canAccessOpfs', canAccessOpfs);
    setProperty(object, 'supportsIndexedDb', supportsIndexedDb);
    setProperty(
        object, 'supportsSharedArrayBuffers', supportsSharedArrayBuffers);

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
  void _send(_PostMessage sender) {
    sender.sendTyped(type, sqlite3Options);
  }
}

extension on _PostMessage {
  void sendTyped(String type, Object? payload, [List<Object>? transfer]) {
    final object = newObject<Object>();
    setProperty(object, 'type', type);
    setProperty(object, 'payload', payload);

    call(object, transfer);
  }
}
