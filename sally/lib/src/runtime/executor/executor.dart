import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sally/sally.dart';
import 'package:sally/src/runtime/executor/stream_queries.dart';
import 'package:sally/src/runtime/executor/type_system.dart';
import 'package:sally/src/runtime/migration.dart';
import 'package:sally/src/runtime/statements/delete.dart';
import 'package:sally/src/runtime/statements/select.dart';
import 'package:sally/src/runtime/statements/update.dart';

/// A base class for all generated databases.
abstract class GeneratedDatabase {
  /// The type system to use with this database. The type system is responsible
  /// for mapping Dart objects into sql expressions and vice-versa.
  final SqlTypeSystem typeSystem;
  /// The executor to use when queries are executed.
  final QueryExecutor executor;
  /// Manages active streams from select statements.
  @visibleForTesting
  StreamQueryStore streamQueries;

  /// Specify the schema version of your database. Whenever you change or add
  /// tables, you should bump this field and provide a [migration] strategy.
  int get schemaVersion;
  /// Defines the migration strategy that will determine how to deal with an
  /// increasing [schemaVersion]. The default value only supports creating the
  /// database by creating all tables known in this database. When you have
  /// changes in your schema, you'll need a custom migration strategy to create
  /// the new tables or change the columns.
  MigrationStrategy get migration => MigrationStrategy();

  /// A list of tables specified in this database.
  List<TableInfo> get allTables;

  GeneratedDatabase(this.typeSystem, this.executor, {this.streamQueries}) {
    streamQueries ??= StreamQueryStore();
    executor?.databaseInfo = this;
  }

  /// Creates a migrator with the provided query executor. We sometimes can't
  /// use the regular [GeneratedDatabase.executor] because migration happens
  /// before that executor is ready.
  Migrator _createMigrator(SqlExecutor executor) => Migrator(this, executor);

  /// Marks the table as updated. This method will be called internally whenever
  /// a update, delete or insert statement is issued on the database. We can
  /// then inform all active select-streams on that table that their snapshot
  /// might be out-of-date and needs to be fetched again.
  void markTableUpdated(String tableName) {
    streamQueries.handleTableUpdates(tableName);
  }

  /// Creates and auto-updating stream from the given select statement. This
  /// method should not be used directly.
  Stream<List<T>> createStream<T>(SelectStatement<dynamic, T> stmt) =>
      streamQueries.registerStream(stmt);

  /// Handles database creation by delegating the work to the [migration]
  /// strategy. This method should not be called by users.
  Future<void> handleDatabaseCreation({@required SqlExecutor executor}) {
    final migrator = _createMigrator(executor);
    return migration.onCreate(migrator);
  }

  /// Handles database updates by delegating the work to the [migration]
  /// strategy. This method should not be called by users.
  Future<void> handleDatabaseVersionChange(
      {@required SqlExecutor executor, int from, int to}) {
    final migrator = _createMigrator(executor);
    return migration.onUpgrade(migrator, from, to);
  }

  /// Starts an [InsertStatement] for a given table. You can use that statement
  /// to write data into the [table] by using [InsertStatement.insert].
  InsertStatement<T> into<T>(TableInfo<dynamic, T> table) =>
      InsertStatement<T>(this, table);

  /// Starts an [UpdateStatement] for the given table. You can use that
  /// statement to update individual rows in that table by setting a where
  /// clause on that table and then use [UpdateStatement.write].
  UpdateStatement<Tbl, ReturnType> update<Tbl, ReturnType>(
          TableInfo<Tbl, ReturnType> table) =>
      UpdateStatement(this, table);

  /// Starts a query on the given table. Queries can be limited with an limit
  /// or a where clause and can either return a current snapshot or a continuous
  /// stream of data
  SelectStatement<Table, ReturnType> select<Table, ReturnType>(
      TableInfo<Table, ReturnType> table) {
    return SelectStatement<Table, ReturnType>(this, table);
  }

  /// Starts a [DeleteStatement] that can be used to delete rows from a table.
  DeleteStatement<Table> delete<Table>(TableInfo<Table, dynamic> table) =>
      DeleteStatement<Table>(this, table);
}

/// A query executor is responsible for executing statements on a database and
/// return their results in a raw form.
abstract class QueryExecutor {
  GeneratedDatabase databaseInfo;

  /// Performs the async [fn] after this executor is ready, or directly if it's
  /// already ready.
  Future<T> doWhenOpened<T>(FutureOr<T> fn(QueryExecutor e)) {
    return ensureOpen().then((_) => fn(this));
  }

  /// Opens the executor, if it has not yet been opened.
  Future<bool> ensureOpen();

  /// Runs a select statement with the given variables and returns the raw
  /// results.
  Future<List<Map<String, dynamic>>> runSelect(
      String statement, List<dynamic> args);

  /// Runs an insert statement with the given variables. Returns the row id or
  /// the auto_increment id of the inserted row.
  Future<int> runInsert(String statement, List<dynamic> args);

  /// Runs an update statement with the given variables and returns how many
  /// rows where affected.
  Future<int> runUpdate(String statement, List<dynamic> args);

  /// Runs an delete statement and returns how many rows where affected.
  Future<int> runDelete(String statement, List<dynamic> args);

  /// Runs a custom SQL statement without any variables. The result of that
  /// statement will be ignored.
  Future<void> runCustom(String statement);
}
