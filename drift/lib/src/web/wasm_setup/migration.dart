import 'dart:typed_data';

import 'package:sqlite3/wasm.dart';

import 'shared.dart';

const paths = {'/database', '/database-journal'};



/// Migrates the drift database identified by [databaseName] from the IndexedDB
/// storage implementation to the OPFS storage implementation.
///
/// Must be called in a dedicated worker, as only those have access to OPFS.
Future<void> migrateFromIndexedDbToOpfs(String databaseName) async {

}

/// Migrates the drift database identified by [databaseName] from the OPFS
/// storage implementation back to IndexedDB.
///
/// Must be called in a dedicated worker, as only those have access to OPFS.
Future<void> migrateFromOpfsToIndexedDb(String databaseName) async {
  final opfs =
      await SimpleOpfsFileSystem.loadFromStorage(pathForOpfs(databaseName));
  final indexedDb = await IndexedDbFileSystem.open(dbName: databaseName);

  await _migrate(opfs, indexedDb);
}

Future<void> _migrate(
    VirtualFileSystem source, VirtualFileSystem target) async {
  for (final path in paths) {
    if (target.xAccess(path, 0) != 0) {
      target.xDelete(path, 0);
    }

    if (source.xAccess(path, 0) != 0) {
      final (file: sourceFile, outFlags: _) =
          source.xOpen(Sqlite3Filename(path), SqlFlag.SQLITE_OPEN_CREATE);
      final (file: targetFile, outFlags: _) =
          target.xOpen(Sqlite3Filename(path), SqlFlag.SQLITE_OPEN_CREATE);

      final buffer = Uint8List(sourceFile.xFileSize());
      sourceFile.xRead(buffer, 0);
      targetFile.xWrite(buffer, 0);

      sourceFile.xClose();
      targetFile.xClose();
    }
  }
}
