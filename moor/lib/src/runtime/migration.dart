import 'dart:async';

import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/structure/columns.dart';
import 'package:moor/src/runtime/structure/table_info.dart';

typedef Future<void> OnCreate(Migrator m);
typedef Future<void> OnUpgrade(Migrator m, int from, int to);

/// Signature of a function that's called after a migration has finished and the
/// database is ready to be used. Useful to populate data.
@deprecated
typedef Future<void> OnMigrationFinished();

/// Signature of a function that's called before a database is marked opened by
/// moor, but after migrations took place. This is a suitable callback to to
/// populate initial data or issue `PRAGMA` statements that you want to use.
/// All queries must be sent to [db] directly, otherwise your code will hang.
/// See the discussion at [QueryEngine.transaction] for details.
typedef OnBeforeOpen = Future<void> Function(
    QueryEngine db, OpeningDetails details);

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
  @Deprecated('Use beforeOpen instead')
  final OnMigrationFinished onFinished;

  /// Executes after the database is ready to be used (ie. it has been opened
  /// and all migrations ran), but before any other queries will be sent. This
  /// makes it a suitable place to populate data after the database has been
  /// created or set sqlite `PRAGMAS` that you need.
  final OnBeforeOpen beforeOpen;

  MigrationStrategy({
    this.onCreate = _defaultOnCreate,
    this.onUpgrade = _defaultOnUpdate,
    this.beforeOpen,
    @Deprecated('This callback is broken. Use beforeOpen instead')
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

  GenerationContext _createContext() {
    return GenerationContext(
        _db.typeSystem, _SimpleSqlAsQueryExecutor(_executor));
  }

  /// Creates the given table if it doesn't exist
  Future<void> createTable(TableInfo table) async {
    final context = _createContext();
    context.buffer.write('CREATE TABLE IF NOT EXISTS ${table.$tableName} (');

    var hasAutoIncrement = false;
    for (var i = 0; i < table.$columns.length; i++) {
      final column = table.$columns[i];

      if (column is GeneratedIntColumn && column.hasAutoIncrement) {
        hasAutoIncrement = true;
      }

      column.writeColumnDefinition(context);

      if (i < table.$columns.length - 1) context.buffer.write(', ');
    }

    final hasPrimaryKey = table.$primaryKey?.isNotEmpty ?? false;
    if (hasPrimaryKey && !hasAutoIncrement) {
      context.buffer.write(', PRIMARY KEY (');
      final pkList = table.$primaryKey.toList(growable: false);
      for (var i = 0; i < pkList.length; i++) {
        final column = pkList[i];

        context.buffer.write(column.$name);

        if (i != pkList.length - 1) context.buffer.write(', ');
      }
      context.buffer.write(')');
    }

    final constraints = table.asDslTable.customConstraints ?? [];

    for (var i = 0; i < constraints.length; i++) {
      context.buffer..write(', ')..write(constraints[i]);
    }

    context.buffer.write(');');

    return issueCustomQuery(context.sql);
  }

  /// Deletes the table with the given name. Note that this function does not
  /// escape the [name] parameter.
  Future<void> deleteTable(String name) async {
    return issueCustomQuery('DROP TABLE IF EXISTS $name;');
  }

  /// Adds the given column to the specified table.
  Future<void> addColumn(TableInfo table, GeneratedColumn column) async {
    final context = _createContext();

    context.buffer.write('ALTER TABLE ${table.$tableName} ADD COLUMN ');
    column.writeColumnDefinition(context);
    context.buffer.write(';');

    return issueCustomQuery(context.sql);
  }

  /// Executes the custom query.
  Future<void> issueCustomQuery(String sql) async {
    return _executor(sql);
  }
}

/// Provides information about whether migrations ran before opening the
/// database.
class OpeningDetails {
  /// The schema version before the database has been opened, or `null` if the
  /// database has just been created.
  final int versionBefore;

  /// The schema version after running migrations.
  final int versionNow;

  /// Whether the database has been created during this session.
  bool get wasCreated => versionBefore == null;

  /// Whether a schema upgrade was performed while opening the database.
  bool get hadUpgrade => !wasCreated && versionBefore != versionNow;

  const OpeningDetails(this.versionBefore, this.versionNow);
}

class _SimpleSqlAsQueryExecutor extends QueryExecutor {
  final SqlExecutor executor;

  _SimpleSqlAsQueryExecutor(this.executor);

  @override
  TransactionExecutor beginTransaction() {
    throw UnsupportedError('Not supported for migrations');
  }

  @override
  Future<bool> ensureOpen() {
    return Future.value(true);
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) {
    throw UnsupportedError('Not supported for migrations');
  }

  @override
  Future<void> runCustom(String statement) {
    return executor(statement);
  }

  @override
  Future<int> runDelete(String statement, List args) {
    throw UnsupportedError('Not supported for migrations');
  }

  @override
  Future<int> runInsert(String statement, List args) {
    throw UnsupportedError('Not supported for migrations');
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(String statement, List args) {
    throw UnsupportedError('Not supported for migrations');
  }

  @override
  Future<int> runUpdate(String statement, List args) {
    throw UnsupportedError('Not supported for migrations');
  }
}
