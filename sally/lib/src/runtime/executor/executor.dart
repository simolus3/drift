import 'package:sally/sally.dart';
import 'package:sally/src/runtime/executor/type_system.dart';
import 'package:sally/src/runtime/migration.dart';
import 'package:sally/src/runtime/statements/delete.dart';
import 'package:sally/src/runtime/statements/select.dart';

/// A base class for all generated databases.
abstract class GeneratedDatabase {
  final SqlTypeSystem typeSystem;
  final QueryExecutor executor;

  int get schemaVersion;
  MigrationStrategy get migration;

  List<TableInfo> get allTables;

  GeneratedDatabase(this.typeSystem, this.executor);

  /// Creates a migrator with the provided query executor. We sometimes can't
  /// use the regular [GeneratedDatabase.executor] because migration happens
  /// before that executor is ready.
  Migrator _createMigrator(QueryExecutor executor) => Migrator(this, executor);

  Future<void> handleDatabaseCreation(QueryExecutor executor) {
    final migrator = _createMigrator(executor);
    return migration.onCreate(migrator);
  }

  Future<void> handleDatabaseVersionChange(QueryExecutor executor, int from, int to) {
    final migrator = _createMigrator(executor);
    return migration.onUpgrade(migrator, from, to);
  }

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
}
