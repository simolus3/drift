// ignore_for_file: public_member_api_docs

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' hide WorkerOptions;
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

  void writeToJs(JSObject object) {
    object['v'] = versionCode.toJS;
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

  static ProtocolVersion fromJsObject(JSObject object) {
    if (object.has('v')) {
      return negotiate((object['v'] as JSNumber).toDartInt);
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

typedef PostMessage = void Function(JSObject? msg, List<JSObject>? transfer);

/// Sealed superclass for JavaScript objects exchanged between the UI tab and
/// workers spawned by drift to find a suitable database implementation.
sealed class WasmInitializationMessage {
  WasmInitializationMessage();

  factory WasmInitializationMessage.fromJs(JSObject jsObject) {
    final type = (jsObject['type'] as JSString).toDart;
    final payload = jsObject['payload'];

    return switch (type) {
      WorkerError.type => WorkerError.fromJsPayload(payload as JSObject),
      ServeDriftDatabase.type =>
        ServeDriftDatabase.fromJsPayload(payload as JSObject),
      StartFileSystemServer.type =>
        StartFileSystemServer.fromJsPayload(payload as JSObject),
      RequestCompatibilityCheck.type =>
        RequestCompatibilityCheck.fromJsPayload(payload),
      DedicatedWorkerCompatibilityResult.type =>
        DedicatedWorkerCompatibilityResult.fromJsPayload(payload as JSObject),
      SharedWorkerCompatibilityResult.type =>
        SharedWorkerCompatibilityResult.fromJsPayload(payload as JSArray),
      DeleteDatabase.type => DeleteDatabase.fromJsPayload(payload as JSAny),
      _ => throw ArgumentError('Unknown type $type'),
    };
  }

  factory WasmInitializationMessage.read(MessageEvent event) {
    return WasmInitializationMessage.fromJs(event.data as JSObject);
  }

  void sendTo(PostMessage sender);

  void sendToWorker(Worker worker) {
    sendTo((msg, transfer) {
      worker.postMessage(msg, (transfer ?? const []).toJS);
    });
  }

  void sendToPort(MessagePort port) {
    sendTo((msg, transfer) {
      port.postMessage(msg, (transfer ?? const []).toJS);
    });
  }

  void sendToClient(DedicatedWorkerGlobalScope worker) {
    sendTo((msg, transfer) {
      worker.postMessage(msg, (transfer ?? const []).toJS);
    });
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

  factory SharedWorkerCompatibilityResult.fromJsPayload(JSArray payload) {
    final asList = payload.toDart;
    final asBooleans = asList.cast<bool>();

    final List<ExistingDatabase> existingDatabases;
    var version = ProtocolVersion.legacy;

    if (asList.length > 5) {
      existingDatabases = EncodeLocations.readFromJs(asList[5] as JSArray);

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
    sender.sendTyped(
        type,
        [
          canSpawnDedicatedWorkers.toJS,
          dedicatedWorkersCanUseOpfs.toJS,
          canUseIndexedDb.toJS,
          indexedDbExists.toJS,
          opfsExists.toJS,
          existingDatabases.encodeToJs(),
          version.versionCode.toJS,
        ].toJS);
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

  factory WorkerError.fromJsPayload(JSObject payload) {
    return WorkerError((payload as JSString).toDart);
  }

  @override
  void sendTo(PostMessage sender) {
    sender.sendTyped(type, error.toJS);
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

  factory ServeDriftDatabase.fromJsPayload(JSObject payload) {
    return ServeDriftDatabase(
      sqlite3WasmUri: Uri.parse((payload['sqlite'] as JSString).toDart),
      port: payload['port'] as MessagePort,
      storage: WasmStorageImplementation.values
          .byName((payload['storage'] as JSString).toDart),
      databaseName: (payload['database'] as JSString).toDart,
      initializationPort: payload['initPort'] as MessagePort?,
      protocolVersion: ProtocolVersion.fromJsObject(payload),
    );
  }

  @override
  void sendTo(PostMessage sender) {
    final object = JSObject()
      ..['sqlite'] = sqlite3WasmUri.toString().toJS
      ..['port'] = port
      ..['storage'] = storage.name.toJS
      ..['database'] = databaseName.toJS
      ..['initPort'] = initializationPort;

    protocolVersion.writeToJs(object);

    sender.sendTyped(type, object, [
      port,
      if (initializationPort != null) initializationPort!,
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

  factory RequestCompatibilityCheck.fromJsPayload(JSAny? payload) {
    return RequestCompatibilityCheck((payload as JSString).toDart);
  }

  @override
  void sendTo(PostMessage sender) {
    sender.sendTyped(type, databaseName.toJS);
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

  factory DedicatedWorkerCompatibilityResult.fromJsPayload(JSObject payload) {
    final existingDatabases = <ExistingDatabase>[];

    if (payload.has('existing')) {
      existingDatabases
          .addAll(EncodeLocations.readFromJs(payload['existing'] as JSArray));
    }

    return DedicatedWorkerCompatibilityResult(
      supportsNestedWorkers:
          (payload['supportsNestedWorkers'] as JSBoolean).toDart,
      canAccessOpfs: (payload['canAccessOpfs'] as JSBoolean).toDart,
      supportsSharedArrayBuffers:
          (payload['supportsSharedArrayBuffers'] as JSBoolean).toDart,
      supportsIndexedDb: (payload['supportsIndexedDb'] as JSBoolean).toDart,
      indexedDbExists: (payload['indexedDbExists'] as JSBoolean).toDart,
      opfsExists: (payload['opfsExists'] as JSBoolean).toDart,
      existingDatabases: existingDatabases,
      version: ProtocolVersion.fromJsObject(payload),
    );
  }

  @override
  void sendTo(PostMessage sender) {
    final object = JSObject()
      ..['supportsNestedWorkers'] = supportsNestedWorkers.toJS
      ..['canAccessOpfs'] = canAccessOpfs.toJS
      ..['supportsIndexedDb'] = supportsIndexedDb.toJS
      ..['supportsSharedArrayBuffers'] = supportsSharedArrayBuffers.toJS
      ..['indexedDbExists'] = indexedDbExists.toJS
      ..['opfsExists'] = opfsExists.toJS
      ..['existing'] = existingDatabases.encodeToJs();
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

  factory StartFileSystemServer.fromJsPayload(JSObject payload) {
    return StartFileSystemServer(payload as WorkerOptions);
  }

  @override
  void sendTo(PostMessage sender) {
    sender.sendTyped(type, sqlite3Options as JSObject);
  }
}

final class DeleteDatabase extends WasmInitializationMessage {
  static const type = 'DeleteDatabase';

  final ExistingDatabase database;

  DeleteDatabase(this.database);

  factory DeleteDatabase.fromJsPayload(JSAny payload) {
    final asList = (payload as JSArray).toDart;
    return DeleteDatabase((
      WebStorageApi.byName[(asList[0] as JSString).toDart]!,
      (asList[1] as JSString).toDart,
    ));
  }

  @override
  void sendTo(PostMessage sender) {
    sender.sendTyped(type, [database.$1.name.toJS, database.$2.toJS].toJS);
  }
}

extension EncodeLocations on List<ExistingDatabase> {
  static List<ExistingDatabase> readFromJs(JSArray object) {
    final existing = <ExistingDatabase>[];

    for (final entry in object.toDart.cast<JSObject>()) {
      existing.add((
        WebStorageApi.byName[(entry['l'] as JSString).toDart]!,
        (entry['n'] as JSString).toDart,
      ));
    }

    return existing;
  }

  JSObject encodeToJs() {
    final existing = <JSObject>[];
    for (final entry in this) {
      existing.add(JSObject()
        ..['l'] = entry.$1.name.toJS
        ..['n'] = entry.$2.toJS);
    }

    return existing.toJS;
  }
}

extension on PostMessage {
  void sendTyped(String type, JSAny? payload, [List<JSObject>? transfer]) {
    final object = JSObject()
      ..['type'] = type.toJS
      ..['payload'] = payload;

    call(object, transfer);
  }
}
