import 'dart:ffi';
import 'dart:io';

import 'package:drift/dialect/sqlite.dart';
import 'package:drift/drift.dart';
import 'package:drift/src/connections/sqlite3/connection.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/open.dart';
import 'package:path/path.dart' as p;

bool _checkedForLocalSqlite3 = false;

String? get expectedLocalSqlite3Path {
  final folder = p.join('.dart_tool', 'sqlite3', 'latest');

  if (Platform.isWindows) {
    return p.join(folder, 'sqlite3.dll');
  } else if (Platform.isMacOS) {
    return p.join(folder, 'libsqlite3.dylib');
  } else if (Platform.isLinux) {
    return p.join(folder, 'libsqlite3.so');
  } else {
    return null;
  }
}

Object? transportRoundtrip(Object? source) {
  return source;
}

/// Checks if a sqlite3 build has been downloaded into [expectedLocalSqlite3Path],
/// usually by the user running `dart run tool/download_sqlite3.dart` before
/// running tests.
///
/// If such file exists, we prefer it over the (potentially outdated) system's
/// sqlite3.
///
/// This needs to be called before using sqlite3 in a test.
void preferLocalSqlite3() {
  if (!_checkedForLocalSqlite3) {
    _checkedForLocalSqlite3 = true;

    final path = expectedLocalSqlite3Path;
    if (path == null) return;

    if (File(path).existsSync()) {
      open.overrideForAll(() => DynamicLibrary.open(p.absolute(path)));
    }
  }
}

Version get sqlite3Version {
  preferLocalSqlite3();
  return sqlite3.version;
}

DriftDatabaseImplementation testInMemoryDatabase([DriftDialect? dialect]) {
  preferLocalSqlite3();

  final resolvedDialect = (dialect ?? const SqliteDialect()) as SqliteDialect;

  return DriftDatabaseImplementation(
    dialect: resolvedDialect,
    openConnection: () async =>
        SqliteConnection(resolvedDialect, sqlite3.openInMemory()),
  );
}
