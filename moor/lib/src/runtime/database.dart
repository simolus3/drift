import 'dart:async';

import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/executor/before_open.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';
import 'package:moor/src/types/type_system.dart';
import 'package:moor/src/runtime/statements/delete.dart';
import 'package:moor/src/runtime/statements/select.dart';
import 'package:moor/src/runtime/statements/update.dart';

const _zoneRootUserKey = #DatabaseConnectionUser;

typedef _CustomWriter<T> = Future<T> Function(
    QueryExecutor e, String sql, List<dynamic> vars);

/// Class that runs queries to a subset of all available queries in a database.
///
/// This comes in handy to structure large amounts of database code better: The
/// migration logic can live in the main [GeneratedDatabase] class, but code
/// can be extracted into [DatabaseAccessor]s outside of that database.
/// For details on how to write a dao, see [UseDao].
abstract class DatabaseAccessor<T extends GeneratedDatabase>
    extends DatabaseConnectionUser with QueryEngine {
  @override
  final bool topLevel = true;

  @protected
  final T db;

  DatabaseAccessor(this.db) : super.delegate(db);
}

/// Manages a [QueryExecutor] and optionally an own [SqlTypeSystem] or
/// [StreamQueryStore] to send queries to the database.
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
  T alias<T extends Table, D extends DataClass>(
      TableInfo<T, D> table, String alias) {
    return table.createAlias(alias).asDslTable;
  }
}

/// Mixin for a [DatabaseConnectionUser]. Provides an API to execute both
/// high-level and custom queries and fetch their results.
mixin QueryEngine on DatabaseConnectionUser {
  /// Whether this connection user is "top level", e.g. there is no parent
  /// connection user. We consider a [GeneratedDatabase] and a
  /// [DatabaseAccessor] to be top-level, while a [Transaction] or a
  /// [BeforeOpenEngine] aren't.
  ///
  /// If any query method is called on a [topLevel] database user, we check if
  /// it could instead be delegated to a child executor. For instance, consider
  /// this code, assuming its part of a subclass of [GeneratedDatabase]:
  /// ```dart
  /// void example() {
  ///  transaction((t) async {
  ///   await update(table).write(/*...*/)
  ///  });
  /// }
  /// ```
  /// Here, the `update` method would be called on the [GeneratedDatabase]
  /// although it is very likely that the user meant to call it on the
  /// [Transaction] t. We can detect this by calling the function passed to
  /// `transaction` in a forked [Zone] storing the transaction in
  @protected
  bool get topLevel => false;

  /// We can detect when a user called methods on the wrong [QueryEngine]
  /// (e.g. calling [GeneratedDatabase.into] in a transaction, where
  /// [Transaction.into] should have been called instead). See the documentation
  /// of [topLevel] on how this works.
  QueryEngine get _resolvedEngine {
    if (!topLevel) {
      // called directly in a transaction / other child callback, so use this
      // instance directly
      return this;
    } else {
      // if an overridden executor has been specified for this zone (this will
      // happen for transactions), use that one.
      final resolved = Zone.current[_zoneRootUserKey];
      return (resolved as QueryEngine) ?? this;
    }
  }

  /// Starts an [InsertStatement] for a given table. You can use that statement
  /// to write data into the [table] by using [InsertStatement.insert].
  @protected
  @visibleForTesting
  InsertStatement<T> into<T extends DataClass>(TableInfo<Table, T> table) =>
      InsertStatement<T>(_resolvedEngine, table);

  /// Starts an [UpdateStatement] for the given table. You can use that
  /// statement to update individual rows in that table by setting a where
  /// clause on that table and then use [UpdateStatement.write].
  @protected
  @visibleForTesting
  UpdateStatement<Tbl, R> update<Tbl extends Table, R extends DataClass>(
          TableInfo<Tbl, R> table) =>
      UpdateStatement(_resolvedEngine, table);

  /// Starts a query on the given table. Queries can be limited with an limit
  /// or a where clause and can either return a current snapshot or a continuous
  /// stream of data
  @protected
  @visibleForTesting
  SimpleSelectStatement<T, R> select<T extends Table, R extends DataClass>(
      TableInfo<T, R> table) {
    return SimpleSelectStatement<T, R>(_resolvedEngine, table);
  }

  /// Starts a [DeleteStatement] that can be used to delete rows from a table.
  @protected
  @visibleForTesting
  DeleteStatement<T, D> delete<T extends Table, D extends DataClass>(
      TableInfo<T, D> table) {
    return DeleteStatement<T, D>(_resolvedEngine, table);
  }

  /// Executes a custom delete or update statement and returns the amount of
  /// rows that have been changed.
  /// You can use the [updates] parameter so that moor knows which tables are
  /// affected by your query. All select streams that depend on a table
  /// specified there will then issue another query.
  @protected
  @visibleForTesting
  Future<int> customUpdate(String query,
      {List<Variable> variables = const [], Set<TableInfo> updates}) async {
    return _customWrite(query, variables, updates, (executor, sql, vars) {
      return executor.runUpdate(sql, vars);
    });
  }

  /// Executes a custom insert statement and returns the last inserted rowid.
  ///
  /// You can tell moor which tables your query is going to affect by using the
  /// [updates] parameter. Query-streams running on any of these tables will
  /// then be re-run.
  @protected
  @visibleForTesting
  Future<int> customInsert(String query,
      {List<Variable> variables = const [], Set<TableInfo> updates}) {
    return _customWrite(query, variables, updates, (executor, sql, vars) {
      return executor.runInsert(sql, vars);
    });
  }

  /// Common logic for [customUpdate] and [customInsert] which takes care of
  /// mapping the variables, running the query and optionally informing the
  /// stream-queries.
  Future<T> _customWrite<T>(String query, List<Variable> variables,
      Set<TableInfo> updates, _CustomWriter<T> writer) async {
    final engine = _resolvedEngine;
    final executor = engine.executor;

    final ctx = GenerationContext.fromDb(engine);
    final mappedArgs = variables.map((v) => v.mapToSimpleValue(ctx)).toList();

    final result =
        await executor.doWhenOpened((e) => writer(e, query, mappedArgs));

    if (updates != null) {
      await engine.streamQueries.handleTableUpdates(updates);
    }

    return result;
  }

  /// Executes a custom select statement once. To use the variables, mark them
  /// with a "?" in your [query]. They will then be changed to the appropriate
  /// value.
  @protected
  @visibleForTesting
  @Deprecated('use customSelectQuery(...).get() instead')
  Future<List<QueryRow>> customSelect(String query,
      {List<Variable> variables = const []}) async {
    return customSelectQuery(query, variables: variables).get();
  }

  /// Creates a stream from a custom select statement.To use the variables, mark
  /// them with a "?" in your [query]. They will then be changed to the
  /// appropriate value. The stream will re-emit items when any table in
  /// [readsFrom] changes, so be sure to set it to the set of tables your query
  /// reads data from.
  @protected
  @visibleForTesting
  @Deprecated('use customSelectQuery(...).watch() instead')
  Stream<List<QueryRow>> customSelectStream(String query,
      {List<Variable> variables = const [], Set<TableInfo> readsFrom}) {
    return customSelectQuery(query, variables: variables, readsFrom: readsFrom)
        .watch();
  }

  /// Creates a custom select statement from the given sql [query]. To run the
  /// query once, use [Selectable.get]. For an auto-updating streams, set the
  /// set of tables the ready [readsFrom] and use [Selectable.watch]. If you
  /// know the query will never emit more than one row, you can also use
  /// [Selectable.getSingle] and [Selectable.watchSingle] which return the item
  /// directly or wrapping it into a list.
  ///
  /// If you use variables in your query (for instance with "?"), they will be
  /// bound to the [variables] you specify on this query.
  @protected
  @visibleForTesting
  Selectable<QueryRow> customSelectQuery(String query,
      {List<Variable> variables = const [],
      Set<TableInfo> readsFrom = const {}}) {
    readsFrom ??= {};
    return CustomSelectStatement(query, variables, readsFrom, _resolvedEngine);
  }

  /// Executes the custom sql [statement] on the database.
  @protected
  @visibleForTesting
  Future<void> customStatement(String statement, [List<dynamic> args]) {
    return _resolvedEngine.executor.runCustom(statement, args);
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
  ///  2. Nested transactions are not supported. Creating another transaction
  ///     inside a transaction returns the parent transaction.
  @protected
  @visibleForTesting
  Future transaction(Future Function() action) async {
    final resolved = _resolvedEngine;
    if (resolved is Transaction) {
      return action();
    }

    final executor = resolved.executor;
    await executor.doWhenOpened((executor) {
      final transactionExecutor = executor.beginTransaction();
      final transaction = Transaction(this, transactionExecutor);

      return _runEngineZoned(transaction, () async {
        var success = false;
        try {
          await action();
          success = true;
        } catch (e) {
          await transactionExecutor.rollback();

          // pass the exception on to the one who called transaction()
          rethrow;
        } finally {
          if (success) {
            // calling complete will also take care of committing the transaction
            await transaction.complete();
          }
        }
      });
    });
  }

  /// Runs [calculation] in a forked [Zone] that has its [_resolvedEngine] set
  /// to the [engine].
  ///
  /// For details, see the documentation at [topLevel].
  @protected
  Future<T> _runEngineZoned<T>(
      QueryEngine engine, Future<T> Function() calculation) {
    return runZoned(calculation, zoneValues: {_zoneRootUserKey: engine});
  }

  /// Will be used by generated code to resolve inline Dart expressions in sql.
  @protected
  GenerationContext $write(Component component) {
    final context = GenerationContext.fromDb(this);

    // we don't want ORDER BY clauses to write the ORDER BY tokens because those
    // are already declared in sql
    if (component is OrderBy) {
      component.writeInto(context, writeOrderBy: false);
    } else {
      component.writeInto(context);
    }

    return context;
  }
}

/// A base class for all generated databases.
abstract class GeneratedDatabase extends DatabaseConnectionUser
    with QueryEngine {
  @override
  final bool topLevel = true;

  /// Specify the schema version of your database. Whenever you change or add
  /// tables, you should bump this field and provide a [migration] strategy.
  int get schemaVersion;

  /// Defines the migration strategy that will determine how to deal with an
  /// increasing [schemaVersion]. The default value only supports creating the
  /// database by creating all tables known in this database. When you have
  /// changes in your schema, you'll need a custom migration strategy to create
  /// the new tables or change the columns.
  MigrationStrategy get migration => MigrationStrategy();
  MigrationStrategy _cachedMigration;
  MigrationStrategy get _resolvedMigration => _cachedMigration ??= migration;

  /// A list of tables specified in this database.
  List<TableInfo> get allTables;

  GeneratedDatabase(SqlTypeSystem types, QueryExecutor executor,
      {StreamQueryStore streamStore})
      : super(types, executor, streamQueries: streamStore) {
    executor?.databaseInfo = this;
  }

  /// Creates a [Migrator] with the provided query executor. Migrators generate
  /// sql statements to create or drop tables.
  ///
  /// This api is mainly used internally in moor, for instance in
  /// [handleDatabaseCreation] and [handleDatabaseVersionChange]. However, it
  /// can also be used if you need to create tables manually and outside of a
  /// [MigrationStrategy]. For almost all use cases, overriding [migration]
  /// should suffice.
  @protected
  Migrator createMigrator([SqlExecutor executor]) {
    final actualExecutor = executor ?? customStatement;
    return Migrator(this, actualExecutor);
  }

  /// Handles database creation by delegating the work to the [migration]
  /// strategy. This method should not be called by users.
  Future<void> handleDatabaseCreation({@required SqlExecutor executor}) {
    final migrator = createMigrator(executor);
    return _resolvedMigration.onCreate(migrator);
  }

  /// Handles database updates by delegating the work to the [migration]
  /// strategy. This method should not be called by users.
  Future<void> handleDatabaseVersionChange(
      {@required SqlExecutor executor, int from, int to}) {
    final migrator = createMigrator(executor);
    return _resolvedMigration.onUpgrade(migrator, from, to);
  }

  /// Handles the before opening callback as set in the [migration]. This method
  /// is used internally by database implementations and should not be called by
  /// users.
  Future<void> beforeOpenCallback(
      QueryExecutor executor, OpeningDetails details) async {
    final migration = _resolvedMigration;

    if (migration.beforeOpen != null) {
      final engine = BeforeOpenEngine(this, executor);
      await _runEngineZoned(engine, () {
        return migration.beforeOpen(details);
      });
    }
  }

  /// Closes this database and releases associated resources.
  Future<void> close() async {
    await executor.close();
  }
}
