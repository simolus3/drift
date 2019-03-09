import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';
import 'package:moor/src/types/type_system.dart';
import 'package:moor/src/runtime/statements/delete.dart';
import 'package:moor/src/runtime/statements/select.dart';
import 'package:moor/src/runtime/statements/update.dart';

/// Class that runs queries to a subset of all available queries in a database.
/// This comes in handy to structure large amounts of database code better: The
/// migration logic can live in the main [GeneratedDatabase] class, but code
/// can be extracted into [DatabaseAccessor]s outside of that database.
abstract class DatabaseAccessor<T extends GeneratedDatabase>
    extends DatabaseConnectionUser with QueryEngine {
  @protected
  final T db;

  DatabaseAccessor(this.db) : super.delegate(db);
}

/// Mediocre class name for something that manages a typesystem to map between
/// Dart types and SQL types and can run sql queries.
abstract class DatabaseConnectionUser {
  /// The type system to use with this database. The type system is responsible
  /// for mapping Dart objects into sql expressions and vice-versa.
  final SqlTypeSystem typeSystem;

  /// The executor to use when queries are executed.
  final QueryExecutor executor;

  /// Manages active streams from select statements.
  @visibleForTesting
  @protected
  StreamQueryStore streamQueries;

  DatabaseConnectionUser(this.typeSystem, this.executor, {this.streamQueries}) {
    streamQueries ??= StreamQueryStore();
  }

  DatabaseConnectionUser.delegate(DatabaseConnectionUser other)
      : typeSystem = other.typeSystem,
        executor = other.executor,
        streamQueries = other.streamQueries;

  /// Marks the table as updated. This method will be called internally whenever
  /// a update, delete or insert statement is issued on the database. We can
  /// then inform all active select-streams on that table that their snapshot
  /// might be out-of-date and needs to be fetched again.
  void markTableUpdated(String tableName) {
    streamQueries.handleTableUpdates(tableName);
  }

  /// Creates and auto-updating stream from the given select statement. This
  /// method should not be used directly.
  Stream<List<T>> createStream<T>(TableChangeListener<List<T>> stmt) =>
      streamQueries.registerStream(stmt);
}

/// Mixin for a [DatabaseConnectionUser]. Provides an API to execute both
/// high-level and custom queries and fetch their results.
mixin QueryEngine on DatabaseConnectionUser {
  /// Starts an [InsertStatement] for a given table. You can use that statement
  /// to write data into the [table] by using [InsertStatement.insert].
  @protected
  @visibleForTesting
  InsertStatement<T> into<T>(TableInfo<dynamic, T> table) =>
      InsertStatement<T>(this, table);

  /// Starts an [UpdateStatement] for the given table. You can use that
  /// statement to update individual rows in that table by setting a where
  /// clause on that table and then use [UpdateStatement.write].
  @protected
  @visibleForTesting
  UpdateStatement<Tbl, ReturnType> update<Tbl, ReturnType>(
          TableInfo<Tbl, ReturnType> table) =>
      UpdateStatement(this, table);

  /// Starts a query on the given table. Queries can be limited with an limit
  /// or a where clause and can either return a current snapshot or a continuous
  /// stream of data
  @protected
  @visibleForTesting
  SelectStatement<Table, ReturnType> select<Table, ReturnType>(
      TableInfo<Table, ReturnType> table) {
    return SelectStatement<Table, ReturnType>(this, table);
  }

  /// Starts a [DeleteStatement] that can be used to delete rows from a table.
  @protected
  @visibleForTesting
  DeleteStatement<Table> delete<Table>(TableInfo<Table, dynamic> table) =>
      DeleteStatement<Table>(this, table);

  /// Executes a custom delete or update statement and returns the amount of
  /// rows that have been changed.
  /// You can use the [updates] parameter so that moor knows which tables are
  /// affected by your query. All select streams that depend on a table
  /// specified there will then issue another query.
  Future<int> customUpdate(String query,
      {List<Variable> variables = const [], Set<TableInfo> updates}) async {
    final ctx = GenerationContext(this);
    final mappedArgs = variables.map((v) => v.mapToSimpleValue(ctx)).toList();

    final affectedRows =
        executor.doWhenOpened((_) => executor.runUpdate(query, mappedArgs));

    if (updates != null) {
      for (var table in updates) {
        await streamQueries.handleTableUpdates(table.$tableName);
      }
    }

    return affectedRows;
  }

  /// Executes a custom select statement once. To use the variables, mark them
  /// with a "?" in your [query]. They will then be changed to the appropriate
  /// value.
  Future<List<QueryRow>> customSelect(String query,
      {List<Variable> variables = const []}) async {
    return CustomSelectStatement(query, variables, <TableInfo>{}, this).read();
  }

  /// Creates a stream from a custom select statement.To use the variables, mark
  /// them with a "?" in your [query]. They will then be changed to the
  /// appropriate value. The stream will re-emit items when any table in
  /// [readsFrom] changes, so be sure to set it to the set of tables your query
  /// reads data from.
  Stream<List<QueryRow>> customSelectStream(String query,
      {List<Variable> variables = const [], Set<TableInfo> readsFrom}) {
    final tables = readsFrom ?? <TableInfo>{};
    return createStream(CustomSelectStatement(query, variables, tables, this));
  }
}

/// A base class for all generated databases.
abstract class GeneratedDatabase extends DatabaseConnectionUser
    with QueryEngine {
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

  GeneratedDatabase(SqlTypeSystem types, QueryExecutor executor,
      {StreamQueryStore streamStore})
      : super(types, executor, streamQueries: streamStore) {
    executor?.databaseInfo = this;
  }

  /// Creates a migrator with the provided query executor. We sometimes can't
  /// use the regular [GeneratedDatabase.executor] because migration happens
  /// before that executor is ready.
  Migrator _createMigrator(SqlExecutor executor) => Migrator(this, executor);

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
}
