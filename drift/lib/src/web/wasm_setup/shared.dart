import 'package:js/js_util.dart';
// ignore: implementation_imports
import 'package:sqlite3/src/wasm/js_interop/file_system_access.dart';

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
