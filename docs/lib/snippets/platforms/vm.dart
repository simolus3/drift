import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// #docregion setup
import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/open.dart';

void main() {
  open.overrideFor(OperatingSystem.linux, _openOnLinux);

  final db = sqlite3.openInMemory();
  db.dispose();
}

DynamicLibrary _openOnLinux() {
  final script = File(Platform.script.toFilePath());
  final libraryNextToScript = File('${script.path}/sqlite3.so');
  return DynamicLibrary.open(libraryNextToScript.path);
}
// _openOnWindows could be implemented similarly by opening `sqlite3.dll`
// #enddocregion setup

// #docregion background-simple
QueryExecutor openDatabase() {
  return NativeDatabase.createInBackground(
    File('path/to/database.db'),
    isolateSetup: () {
      open.overrideFor(OperatingSystem.linux, _openOnLinux);
    },
  );
}
// #enddocregion background-simple

// #docregion background-pool
QueryExecutor openMultiThreadedDatabase() {
  return NativeDatabase.createInBackground(
    File('path/to/database.db'),
    isolateSetup: () {
      open.overrideFor(OperatingSystem.linux, _openOnLinux);
    },
    setup: (database) {
      // This is important, as accessing the database across threads otherwise
      // causes "database locked" errors.
      // With write-ahead logging (WAL) enabled, a single writer and multiple
      // readers can operate on the database in parallel.
      database.execute('pragma journal_mode = WAL;');
    },
    readPool: 4,
  );
}
// #enddocregion background-pool
