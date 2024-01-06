// ignore_for_file: public_member_api_docs

import 'dart:html';
import 'dart:js';

import 'package:js/js_util.dart';
import 'package:sqlite3/wasm.dart';

import 'types.dart';

/// Due to in-browser caching or users not updating their `drift_worker.dart`
/// file after updating drift, the main web app and the workers may be compiled
/// with different versions of drift. To avoid inconsistencies in the
/// communication channel between them, they compare their versions in a
/// handshake and only use features supported by both.
class ProtocolVersion {
  final int versionCode;

  const ProtocolVersion._(this.versionCode);

  void writeToJs(Object object) {
    setProperty(object, 'v', versionCode);
  }

  bool operator >=(ProtocolVersion other) {
    return versionCode >= other.versionCode;
  }

  static ProtocolVersion negotiate(int? versionCode) {
    return switch (versionCode) {
      null => legacy,
      <= 0 => legacy,
      1 => v1,
      > 1 => current,
      _ => throw AssertionError(),
    };
  }

  static ProtocolVersion fromJsObject(Object object) {
    if (hasProperty(object, 'v')) {
      return negotiate(getProperty<int>(object, 'v'));
    } else {
      return legacy;
    }
  }

  /// The protocol version used for drift versions up to 2.14 - these don't have
  /// a version marker anywhere.
  static const legacy = ProtocolVersion._(0);

  /// This version makes workers report their supported protocol version.
  ///
  /// When both the client and the involved worker support this version, an
  /// explicit close notification is sent from clients to workers when closing
  /// databases. This allows workers to release resources more effieciently.
  static const v1 = ProtocolVersion._(1);

  static const current = v1;
}

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
      DeleteDatabase.type => DeleteDatabase.fromJsPayload(payload!),
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

sealed class CompatibilityResult extends WasmInitializationMessage {
  /// All existing databases.
  ///
  /// This list is only reported by the drift worker shipped with drift 2.11.
  /// When an older worker is used, only [indexedDbExists] and [opfsExists] can
  /// be used to check whether the database exists.
  final List<ExistingDatabase> existingDatabases;

  /// The latest protocol version spoken by the worker.
  ///
  /// Workers only started to report their version in drift 2.15, we assume
  /// [ProtocolVersion.legacy] for workers that don't report their version.
  final ProtocolVersion version;

  final bool indexedDbExists;
  final bool opfsExists;

  Iterable<MissingBrowserFeature> get missingFeatures;

  CompatibilityResult({
    required this.existingDatabases,
    required this.indexedDbExists,
    required this.opfsExists,
    required this.version,
  });
}

/// A message used by the shared worker to report compatibility results.
///
/// It describes the features available from the shared worker, which the tab
/// can use to infer a desired storage implementation, or whether the shared
/// worker should be used at all.
final class SharedWorkerCompatibilityResult extends CompatibilityResult {
  static const type = 'SharedWorkerCompatibilityResult';

  final bool canSpawnDedicatedWorkers;
  final bool dedicatedWorkersCanUseOpfs;
  final bool canUseIndexedDb;

  SharedWorkerCompatibilityResult({
    required this.canSpawnDedicatedWorkers,
    required this.dedicatedWorkersCanUseOpfs,
    required this.canUseIndexedDb,
    required super.indexedDbExists,
    required super.opfsExists,
    required super.existingDatabases,
    required super.version,
  });

  factory SharedWorkerCompatibilityResult.fromJsPayload(Object payload) {
    final asList = payload as List;
    final asBooleans = asList.cast<bool>();

    final List<ExistingDatabase> existingDatabases;
    var version = ProtocolVersion.legacy;

    if (asList.length > 5) {
      existingDatabases =
          EncodeLocations.readFromJs(asList[5] as List<dynamic>);

      if (asList.length > 6) {
        version = ProtocolVersion.negotiate(asList[6] as int);
      }
    } else {
      existingDatabases = const [];
    }

    return SharedWorkerCompatibilityResult(
      canSpawnDedicatedWorkers: asBooleans[0],
      dedicatedWorkersCanUseOpfs: asBooleans[1],
      canUseIndexedDb: asBooleans[2],
      indexedDbExists: asBooleans[3],
      opfsExists: asBooleans[4],
      existingDatabases: existingDatabases,
      version: version,
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
      existingDatabases.encodeToJs(),
      version.versionCode,
    ]);
  }

  @override
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
  final ProtocolVersion protocolVersion;

  ServeDriftDatabase({
    required this.sqlite3WasmUri,
    required this.port,
    required this.storage,
    required this.databaseName,
    required this.initializationPort,
    required this.protocolVersion,
  });

  factory ServeDriftDatabase.fromJsPayload(Object payload) {
    return ServeDriftDatabase(
      sqlite3WasmUri: Uri.parse(getProperty(payload, 'sqlite')),
      port: getProperty(payload, 'port'),
      storage: WasmStorageImplementation.values
          .byName(getProperty(payload, 'storage')),
      databaseName: getProperty(payload, 'database'),
      initializationPort: getProperty(payload, 'initPort'),
      protocolVersion: ProtocolVersion.fromJsObject(payload),
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
    protocolVersion.writeToJs(object);

    sender.sendTyped(type, object, [
      port,
      if (initPort != null) initPort,
    ]);
  }
}

final class RequestCompatibilityCheck extends WasmInitializationMessage {
  static const type = 'RequestCompatibilityCheck';

  /// The database name to check when reporting whether it exists already.
  ///
  /// Older versions of the drif worker only support checking a single database
  /// name. On newer workers, this field is ignored.
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

final class DedicatedWorkerCompatibilityResult extends CompatibilityResult {
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
    required super.indexedDbExists,
    required super.opfsExists,
    required super.existingDatabases,
    required super.version,
  });

  factory DedicatedWorkerCompatibilityResult.fromJsPayload(Object payload) {
    final existingDatabases = <ExistingDatabase>[];

    if (hasProperty(payload, 'existing')) {
      existingDatabases
          .addAll(EncodeLocations.readFromJs(getProperty(payload, 'existing')));
    }

    return DedicatedWorkerCompatibilityResult(
      supportsNestedWorkers: getProperty(payload, 'supportsNestedWorkers'),
      canAccessOpfs: getProperty(payload, 'canAccessOpfs'),
      supportsSharedArrayBuffers:
          getProperty(payload, 'supportsSharedArrayBuffers'),
      supportsIndexedDb: getProperty(payload, 'supportsIndexedDb'),
      indexedDbExists: getProperty(payload, 'indexedDbExists'),
      opfsExists: getProperty(payload, 'opfsExists'),
      existingDatabases: existingDatabases,
      version: ProtocolVersion.fromJsObject(payload),
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
    setProperty(object, 'existing', existingDatabases.encodeToJs());
    version.writeToJs(object);

    sender.sendTyped(type, object);
  }

  @override
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

final class DeleteDatabase extends WasmInitializationMessage {
  static const type = 'DeleteDatabase';

  final ExistingDatabase database;

  DeleteDatabase(this.database);

  factory DeleteDatabase.fromJsPayload(Object payload) {
    final asList = payload as List<Object?>;
    return DeleteDatabase((
      WebStorageApi.byName[asList[0] as String]!,
      asList[1] as String,
    ));
  }

  @override
  void sendTo(PostMessage sender) {
    sender.sendTyped(type, [database.$1.name, database.$2]);
  }
}

extension EncodeLocations on List<ExistingDatabase> {
  static List<ExistingDatabase> readFromJs(List<Object?> object) {
    final existing = <ExistingDatabase>[];

    for (final entry in object) {
      existing.add((
        WebStorageApi.byName[getProperty(entry as Object, 'l')]!,
        getProperty(entry, 'n'),
      ));
    }

    return existing;
  }

  Object encodeToJs() {
    final existing = JsArray<Object>();
    for (final entry in this) {
      final object = newObject<Object>();
      setProperty(object, 'l', entry.$1.name);
      setProperty(object, 'n', entry.$2);

      existing.add(object);
    }

    return existing;
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
