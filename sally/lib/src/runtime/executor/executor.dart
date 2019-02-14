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
  final SqlTypeSystem typeSystem;
  final QueryExecutor executor;
  final StreamQueryStore streamQueries = StreamQueryStore();

  int get schemaVersion;
  MigrationStrategy get migration;

  List<TableInfo> get allTables;

  GeneratedDatabase(this.typeSystem, this.executor);

  /// Creates a migrator with the provided query executor. We sometimes can't
  /// use the regular [GeneratedDatabase.executor] because migration happens
  /// before that executor is ready.
  Migrator _createMigrator(SqlExecutor executor) => Migrator(this, executor);

  void markTableUpdated(String tableName) {
    streamQueries.handleTableUpdates(tableName);
  }

  Future<void> handleDatabaseCreation({@required SqlExecutor executor}) {
    final migrator = _createMigrator(executor);
    return migration.onCreate(migrator);
  }

  Future<void> handleDatabaseVersionChange(
      {@required SqlExecutor executor, int from, int to}) {
    final migrator = _createMigrator(executor);
    return migration.onUpgrade(migrator, from, to);
  }

  InsertStatement<T> into<T>(TableInfo<dynamic, T> table) =>
      InsertStatement<T>(this, table);

  UpdateStatement<Tbl, ReturnType> update<Tbl, ReturnType>(
          TableInfo<Tbl, ReturnType> table) =>
      UpdateStatement(this, table);

  SelectStatement<Table, ReturnType> select<Table, ReturnType>(
      TableInfo<Table, ReturnType> table) {
    return SelectStatement<Table, ReturnType>(this, table);
  }

  DeleteStatement<Table> delete<Table>(TableInfo<Table, dynamic> table) =>
      DeleteStatement<Table>(this, table);
}

abstract class QueryExecutor {
  GeneratedDatabase databaseInfo;

  Future<bool> ensureOpen();

  Future<List<Map<String, dynamic>>> runSelect(
      String statement, List<dynamic> args);

  Future<int> runInsert(String statement, List<dynamic> args);

  Future<int> runUpdate(String statement, List<dynamic> args);

  Future<int> runDelete(String statement, List<dynamic> args);

  Future<void> runCustom(String statement);
}
