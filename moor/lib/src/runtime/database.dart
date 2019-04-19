import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';
import 'package:moor/src/types/type_system.dart';
import 'package:moor/src/runtime/statements/delete.dart';
import 'package:moor/src/runtime/statements/select.dart';
import 'package:moor/src/runtime/statements/update.dart';

/// Class that runs queries to a subset of all available queries in a database.
///
/// This comes in handy to structure large amounts of database code better: The
/// migration logic can live in the main [GeneratedDatabase] class, but code
/// can be extracted into [DatabaseAccessor]s outside of that database.
/// For details on how to write a dao, see [UseDao].
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

  DatabaseConnectionUser.delegate(DatabaseConnectionUser other,
      {SqlTypeSystem typeSystem,
      QueryExecutor executor,
      StreamQueryStore streamQueries})
      : typeSystem = typeSystem ?? other.typeSystem,
        executor = executor ?? other.executor,
        streamQueries = streamQueries ?? other.streamQueries;

  /// Marks the tables as updated. This method will be called internally
  /// whenever a update, delete or insert statement is issued on the database.
  /// We can then inform all active select-streams on those tables that their
  /// snapshot might be out-of-date and needs to be fetched again.
  void markTablesUpdated(Set<TableInfo> tables) {
    streamQueries.handleTableUpdates(tables);
  }

  /// Creates and auto-updating stream from the given select statement. This
  /// method should not be used directly.
  Stream<T> createStream<T>(QueryStreamFetcher<T> stmt) =>
      streamQueries.registerStream(stmt);

  /// Creates a copy of the table with an alias so that it can be used in the
  /// same query more than once.
  ///
  /// Example which uses the same table (here: points) more than once to
  /// differentiate between the start and end point of a route:
  /// ```
  /// var source = alias(points, 'source');
  /// var destination = alias(points, 'dest');
  ///
  /// select(routes).join([
  ///   innerJoin(source, routes.startPoint.equalsExp(source.id)),
  ///   innerJoin(destination, routes.startPoint.equalsExp(destination.id)),
  /// ]);
  /// ```
  T alias<T extends Table, D>(TableInfo<T, D> table, String alias) {
    return table.createAlias(alias).asDslTable;
  }
}

/// Mixin for a [DatabaseConnectionUser]. Provides an API to execute both
/// high-level and custom queries and fetch their results.
mixin QueryEngine on DatabaseConnectionUser {
  /// Starts an [InsertStatement] for a given table. You can use that statement
  /// to write data into the [table] by using [InsertStatement.insert].
  @protected
  @visibleForTesting
  InsertStatement<T> into<T>(TableInfo<Table, T> table) =>
      InsertStatement<T>(this, table);

  /// Starts an [UpdateStatement] for the given table. You can use that
  /// statement to update individual rows in that table by setting a where
  /// clause on that table and then use [UpdateStatement.write].
  @protected
  @visibleForTesting
  UpdateStatement<Tbl, ReturnType> update<Tbl extends Table, ReturnType>(
          TableInfo<Tbl, ReturnType> table) =>
      UpdateStatement(this, table);

  /// Starts a query on the given table. Queries can be limited with an limit
  /// or a where clause and can either return a current snapshot or a continuous
  /// stream of data
  @protected
  @visibleForTesting
  SimpleSelectStatement<T, ReturnType> select<T extends Table, ReturnType>(
      TableInfo<T, ReturnType> table) {
    return SimpleSelectStatement<T, ReturnType>(this, table);
  }

  /// Starts a [DeleteStatement] that can be used to delete rows from a table.
  @protected
  @visibleForTesting
  DeleteStatement<T, Entity> delete<T extends Table, Entity>(
      TableInfo<T, Entity> table) {
    return DeleteStatement<T, Entity>(this, table);
  }

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
      await streamQueries.handleTableUpdates(updates);
    }

    return affectedRows;
  }

  /// Executes a custom select statement once. To use the variables, mark them
  /// with a "?" in your [query]. They will then be changed to the appropriate
  /// value.
  Future<List<QueryRow>> customSelect(String query,
      {List<Variable> variables = const []}) async {
    return CustomSelectStatement(query, variables, <TableInfo>{}, this)
        .execute();
  }

  /// Creates a stream from a custom select statement.To use the variables, mark
  /// them with a "?" in your [query]. They will then be changed to the
  /// appropriate value. The stream will re-emit items when any table in
  /// [readsFrom] changes, so be sure to set it to the set of tables your query
  /// reads data from.
  Stream<List<QueryRow>> customSelectStream(String query,
      {List<Variable> variables = const [], Set<TableInfo> readsFrom}) {
    final tables = readsFrom ?? <TableInfo>{};
    final statement = CustomSelectStatement(query, variables, tables, this);
    return createStream(statement.constructFetcher());
  }

  /// Executes [action] in a transaction, which means that all its queries and
  /// updates will be called atomically.
  ///
  /// Please be aware of the following limitations of transactions:
  ///  1. Inside a transaction, auto-updating streams cannot be created. This
  ///     operation will throw at runtime. The reason behind this is that a
  ///     stream might have a longer lifespan than a transaction, but it still
  ///     needs to know about the transaction because the data in a transaction
  ///     might be different than that of the "global" database instance.
  ///  2. Nested transactions are not supported. Calling
  ///     [GeneratedDatabase.transaction] on the [QueryEngine] passed to the [action]
  ///     will throw.
  ///  3. The code inside [action] must not call any method of this
  ///     [GeneratedDatabase]. Doing so will cause a dead-lock. Instead, all
  ///     queries and updates must be sent to the [QueryEngine] passed to the
  ///     [action] function.
  Future transaction(Future Function(QueryEngine transaction) action) async {
    await executor.doWhenOpened((executor) async {
      final transaction = Transaction(this, executor.beginTransaction());

      try {
        await action(transaction);
      } finally {
        await transaction.complete();
      }
    });
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
