import 'dart:async';

import 'package:moor/moor.dart';
import 'package:moor/src/runtime/structure/columns.dart';
import 'package:moor/src/runtime/structure/table_info.dart';

typedef Future<void> OnCreate(Migrator m);
typedef Future<void> OnUpgrade(Migrator m, int from, int to);

/// Signature of a function that's called after a migration has finished and the
/// database is ready to be used. Useful to populate data.
typedef Future<void> OnMigrationFinished();

Future<void> _defaultOnCreate(Migrator m) => m.createAllTables();
Future<void> _defaultOnUpdate(Migrator m, int from, int to) async =>
    throw Exception("You've bumped the schema version for your moor database "
        "but didn't provide a strategy for schema updates. Please do that by "
        'adapting the migrations getter in your database class.');

class MigrationStrategy {
  /// Executes when the database is opened for the first time.
  final OnCreate onCreate;

  /// Executes when the database has been opened previously, but the last access
  /// happened at a lower [GeneratedDatabase.schemaVersion].
  final OnUpgrade onUpgrade;

  /// Executes after the database is ready and all migrations ran, but before
  /// any other queries will be executed, making this method suitable to
  /// populate data.
  final OnMigrationFinished onFinished;

  MigrationStrategy({
    this.onCreate = _defaultOnCreate,
    this.onUpgrade = _defaultOnUpdate,
    this.onFinished,
  });
}

/// A function that executes queries and ignores what they return.
typedef Future<void> SqlExecutor(String sql);

class Migrator {
  final GeneratedDatabase _db;
  final SqlExecutor _executor;

  Migrator(this._db, this._executor);

  /// Creates all tables specified for the database, if they don't exist
  Future<void> createAllTables() async {
    return Future.wait(_db.allTables.map(createTable));
  }

  /// Creates the given table if it doesn't exist
  Future<void> createTable(TableInfo table) async {
    final sql = StringBuffer()
      ..write('CREATE TABLE IF NOT EXISTS ${table.$tableName} (');

    var hasAutoIncrement = false;
    for (var i = 0; i < table.$columns.length; i++) {
      final column = table.$columns[i];

      if (column is GeneratedIntColumn && column.hasAutoIncrement) {
        hasAutoIncrement = true;
      }

      column.writeColumnDefinition(sql);

      if (i < table.$columns.length - 1) sql.write(', ');
    }

    if (table.$primaryKey != null && !hasAutoIncrement) {
      sql.write(', PRIMARY KEY (');
      final pkList = table.$primaryKey.toList(growable: false);
      for (var i = 0; i < pkList.length; i++) {
        final column = pkList[i];

        sql.write(column.$name);

        if (i != pkList.length - 1) sql.write(', ');
      }
      sql.write(')');
    }

    final constraints = table.asDslTable.customConstraints ?? [];

    for (var i = 0; i < constraints.length; i++) {
      sql..write(', ')..write(constraints[i]);
    }

    sql.write(');');

    return issueCustomQuery(sql.toString());
  }

  /// Deletes the table with the given name. Note that this function does not
  /// escape the [name] parameter.
  Future<void> deleteTable(String name) async {
    return issueCustomQuery('DROP TABLE IF EXISTS $name;');
  }

  /// Adds the given column to the specified table.
  Future<void> addColumn(TableInfo table, GeneratedColumn column) async {
    final sql = StringBuffer();

    // ignore: cascade_invocations
    sql.write('ALTER TABLE ${table.$tableName} ADD COLUMN ');
    column.writeColumnDefinition(sql);
    sql.write(';');

    return issueCustomQuery(sql.toString());
  }

  /// Executes the custom query.
  Future<void> issueCustomQuery(String sql) async {
    return _executor(sql);
  }
}
