part of 'runtime_api.dart';

/// A database connection managed by drift. This consists of two components:
///
/// - a [QueryExecutor], which runs sql statements.
/// - a [StreamQueryStore], which dispatches table changes to listening queries,
///   on which the auto-updating queries are based.
class DatabaseConnection implements QueryExecutor {
  /// The executor to use when queries are executed.
  final QueryExecutor executor;

  /// Manages active streams from select statements.
  final StreamQueryStore streamQueries;

  /// Constructs a raw database connection from the [executor] and optionally a
  /// specified [streamQueries] implementation to use.
  DatabaseConnection(this.executor, {StreamQueryStore? streamQueries})
      : streamQueries = streamQueries ?? StreamQueryStore();

  /// Constructs a [DatabaseConnection] from the [QueryExecutor] by using the
  /// default type system and a new [StreamQueryStore].
  @Deprecated('Use the default unnamed constructor of `DatabaseConnection` '
      'instead')
  DatabaseConnection.fromExecutor(QueryExecutor executor) : this(executor);

  /// Database connection that is instantly available, but delegates work to a
  /// connection only available through a `Future`.
  ///
  /// This can be useful in scenarios where you need to obtain a database
  /// instance synchronously, but need an async setup. A prime example here is
  /// `DriftIsolate`:
  ///
  /// ```dart
  /// @DriftDatabase(...)
  /// class MyDatabase extends _$MyDatabase {
  ///   MyDatabase._connect(DatabaseConnection c): super.connect(c);
  ///
  ///   factory MyDatabase.fromIsolate(DriftIsolate isolate) {
  ///     return MyDatabase._connect(
  ///       // isolate.connect() returns a future, but we can still return a
  ///       // database synchronously thanks to DatabaseConnection.delayed!
  ///       DatabaseConnection.delayed(isolate.connect()),
  ///     );
  ///   }
  /// }
  /// ```
  factory DatabaseConnection.delayed(FutureOr<DatabaseConnection> connection,
      {SqlDialect dialect = SqlDialect.sqlite}) {
    if (connection is DatabaseConnection) {
      return connection;
    }

    return DatabaseConnection(
      LazyDatabase(() async => (await connection).executor, dialect: dialect),
      streamQueries: DelayedStreamQueryStore(
        connection.then((conn) => conn.streamQueries),
      ),
    );
  }

  /// Returns a database connection that is identical to this one, except that
  /// it uses the provided [executor].
  DatabaseConnection withExecutor(QueryExecutor executor) {
    return DatabaseConnection(executor, streamQueries: streamQueries);
  }

  @override
  TransactionExecutor beginTransaction() => executor.beginTransaction();

  @override
  Future<void> close() => executor.close();

  @override
  SqlDialect get dialect => executor.dialect;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) => executor.ensureOpen(user);

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      executor.runBatched(statements);

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      executor.runCustom(statement, args);

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      executor.runDelete(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      executor.runInsert(statement, args);

  @override
  Future<List<Map<String, Object?>>> runSelect(
          String statement, List<Object?> args) =>
      executor.runSelect(statement, args);

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      executor.runUpdate(statement, args);
}
