import 'dart:async';
import 'dart:io';

import 'package:drift3/drift.dart';
import 'package:drift_sqlite/drift_sqlite.dart';
import 'package:drift_sqlite/native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'connect.dart';

@internal
bool hasConfiguredSqlite = false;

/// Native implementation for drift databases based on
/// `sqlite3_connection_pool`.
DriftConnection driftDatabase({
  required String name,
  DriftWebOptions? web,
  DriftNativeOptions? native,
}) {
  Future<File> lookupDatabaseFile() async {
    if (native?.databasePath case final lookupPath?) {
      return File(await lookupPath());
    } else {
      final resolvedDirectory =
          await (native?.databaseDirectory ??
              getApplicationDocumentsDirectory)();

      return File(
        p.join(switch (resolvedDirectory) {
          Directory(:final path) => path,
          final String path => path,
          final other => throw ArgumentError.value(
            other,
            'databaseDirectory',
            'databaseDirectory on DriftNativeOptions must resolve to a '
                'directory or a path as string.',
          ),
        }, '$name.sqlite'),
      );
    }
  }

  return DriftConnection.delayed(() async {
    final file = await lookupDatabaseFile();
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    if (!hasConfiguredSqlite) {
      // Make sqlite3 pick a more suitable location for temporary files - the
      // one from the system may be inaccessible due to sandboxing.
      final cachebase =
          await (native?.tempDirectoryPath?.call() ??
              getTemporaryDirectory().then((d) => d.path));

      if (cachebase != null) {
        // We can't access /tmp on Android, which sqlite3 would try by default.
        // Explicitly tell it about the correct temporary directory.
        sqlite3.tempDirectory = cachebase;
      }

      hasConfiguredSqlite = true;
    }

    final pool = sqliteConnectionPool(
      file: file,
      configureDatabase: native?.setup,
    );

    return pool;
  }, dialect: SqliteDialect.new);
}
