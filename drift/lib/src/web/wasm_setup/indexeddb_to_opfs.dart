import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sqlite3/wasm.dart';
import 'package:web/web.dart';

import 'shared.dart';

/// Moves a SQLite database stored in IndexedDB to OPFS.
///
/// Because this only uses asynchronous web file system APIs, it can run in the
/// main tab and doesn't have to run in a worker.
Future<void> moveIndexedDBDatabaseToOpfs(String databaseName) async {
  final existingVfs = await IndexedDbFileSystem.open(dbName: databaseName);
  final createDirectory = FileSystemGetDirectoryOptions(create: true);
  final createFile = FileSystemGetFileOptions(create: true);

  final driftDbRoot = await opfsDriftDirectoryHandle(createDirectory);
  if (driftDbRoot == null) {
    throw MoveIndexedDbToOpfsException._(
        databaseName, 'OPFS does not appear to be available.');
  }
  final dbRoot = await driftDbRoot
      .getDirectoryHandle(databaseName, createDirectory)
      .toDart;

  Future<bool> copyFile(String file) async {
    VirtualFileSystemFile old;
    try {
      old = existingVfs.xOpen(Sqlite3Filename('/$file'), 0).file;
    } on VfsException {
      // Doesn't exist.
      return false;
    }

    final buffer = Uint8List(old.xFileSize());
    old.xRead(buffer, 0);
    old.xClose();

    final target = await dbRoot.getFileHandle(file, createFile).toDart;
    final writable = await target
        .createWritable(
            FileSystemCreateWritableOptions(keepExistingData: false))
        .toDart;
    await writable.write(buffer.toJS).toDart;
    await writable.close().toDart;
    return true;
  }

  final journalExists = await copyFile('database-journal');
  final mainFileExists = await copyFile('database');

  {
    // We use a meta file storing two bytes representing whether the database
    // file exist. For details, see SimpleOpfsFileSystem in package:sqlite3.
    final metaTarget = await dbRoot.getFileHandle('meta', createFile).toDart;
    final metaWriter = await metaTarget
        .createWritable(
            FileSystemCreateWritableOptions(keepExistingData: false))
        .toDart;
    final buffer = Uint8List(2);
    buffer[0] = mainFileExists ? 1 : 0;
    buffer[1] = journalExists ? 1 : 0;
    await metaWriter.write(buffer.toJS).toDart;
    await metaWriter.close().toDart;
  }

  try {
    await existingVfs.close();
    await IndexedDbFileSystem.deleteDatabase(databaseName);
  } catch (e) {
    // At this point, drift would still use the new OPFS database because it
    // would be detected as existing. Deleting the old one saves space, but is
    // not strictly required either.
  }
}

/// An exception thrown by [moveIndexedDbDatabaseToOpfs] if an unexpected error
/// occurs.
final class MoveIndexedDbToOpfsException implements Exception {
  final String _databaseName;
  final String _message;

  MoveIndexedDbToOpfsException._(this._databaseName, this._message);

  @override
  String toString() {
    return 'Could not move $_databaseName from IndexedDB to OPFS: $_message';
  }
}
