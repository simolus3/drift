/// This file is responsible for opening a suitable WASM sqlite3 database based
/// on the features available in the browsing context we're in.
///
/// The main challenge of hosting a sqlite3 database in the browser is the
/// implementation of a persistence solution. Being a C library, sqlite3 expects
/// synchronous access to a file system, which is tricky to implement with
/// asynchronous
library;

import 'dart:html';

import 'package:drift/wasm.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
// ignore: implementation_imports
import 'package:sqlite3/src/wasm/js_interop/file_system_access.dart';

@JS()
@anonymous
class WorkerInitializationMessage {
  external String get type;
  external Object get payload;

  external factory WorkerInitializationMessage(
      {required String type, required Object payload});
}

@JS()
@anonymous
class SharedWorkerSupportedFlags {
  static const type = 'shared-supported';

  external bool get canSpawnDedicatedWorkers;
  external bool get dedicatedCanUseOpfs;
  external bool get canUseIndexedDb;

  external factory SharedWorkerSupportedFlags({
    required bool canSpawnDedicatedWorkers,
    required bool dedicatedCanUseOpfs,
    required bool canUseIndexedDb,
  });
}

@JS()
@anonymous
class DedicatedWorkerPurpose {
  static const type = 'dedicated-worker-purpose';

  static const purposeSharedOpfs = 'opfs-shared';

  external String get purpose;

  external factory DedicatedWorkerPurpose({required String purpose});
}

@JS()
@anonymous
class WorkerSetupError {
  static const type = 'worker-error';
}

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
  }

  throw 'todo';
}

/// Checks whether the OPFS API is likely to be correctly implemented in the
/// current browser.
///
/// Since OPFS uses the synchronous file system access API, this method can only
/// return true when called in a dedicated worker.
Future<bool> checkOpfsSupport() async {
  final storage = storageManager;
  if (storage == null) return false;

  final opfsRoot = await storage.directory;
  const testFileName = '_drift_feature_detection';

  FileSystemFileHandle? fileHandle;
  FileSystemSyncAccessHandle? openedFile;

  try {
    fileHandle = await opfsRoot.openFile(testFileName, create: true);
    openedFile = await fileHandle.createSyncAccessHandle();

    // In earlier versions of the OPFS standard, some methods like `getSize()`
    // on a sync file handle have actually been asynchronous. We don't support
    // Browsers that implement the outdated spec.
    final getSizeResult = callMethod<Object?>(openedFile, 'getSize', []);
    if (typeofEquals<Object?>(getSizeResult, 'object')) {
      // Returned a promise, that's no good.
      await promiseToFuture<Object?>(getSizeResult!);
      return false;
    }

    return true;
  } on Object {
    return false;
  } finally {
    if (openedFile != null) {
      openedFile.close();
    }

    if (fileHandle != null) {
      await opfsRoot.removeEntry(testFileName);
    }
  }
}

Future<bool> checkIndexedDbSupport() async {
  return true;
}
