/// Experimental Drift integration for MariaDB.
@experimental
library;

import 'package:drift3_preview/drift.dart';
import 'package:drift_mariadb/src/dialect.dart';
import 'package:drift_mariadb/src/session.dart';
import 'package:meta/meta.dart';
import 'package:mysql_client/mysql_client.dart';

export 'src/dialect.dart' show MariaDbDialect;
export 'src/session.dart' show MariaDbSession;

/// Creates a [DriftConnection] that can be passed to generated database
/// classes.
DriftConnection mariaDbDriftConnection(
  Future<MySQLConnectionPool> Function() openPool, {
  bool enableMigrations = true,
}) {
  return DriftConnection(
    dialect: (_) => const MariaDbDialect(),
    openConnection: (_) async {
      return MariaDbSession(await openPool(), enableMigrations);
    },
  );
}
