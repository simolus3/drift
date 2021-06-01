part of 'runtime_api.dart';

/// A database connection managed by moor. Contains three components:
/// - a [SqlTypeSystem], which is responsible to map between Dart types and
///   values understood by the database engine.
/// - a [QueryExecutor], which runs sql commands
/// - a [StreamQueryStore], which dispatches table changes to listening queries,
///   on which the auto-updating queries are based.
class DatabaseConnection {
  /// The type system to use with this database. The type system is responsible
  /// for mapping Dart objects into sql expressions and vice-versa.
  @Deprecated('Only the default type system is supported')
  final SqlTypeSystem typeSystem;

  /// The executor to use when queries are executed.
  final QueryExecutor executor;

  /// Manages active streams from select statements.
  final StreamQueryStore streamQueries;

  /// Constructs a raw database connection from the three components.
  DatabaseConnection(this.typeSystem, this.executor, this.streamQueries);

  /// Constructs a [DatabaseConnection] from the [QueryExecutor] by using the
  /// default type system and a new [StreamQueryStore].
  DatabaseConnection.fromExecutor(this.executor)
      : typeSystem = SqlTypeSystem.defaultInstance,
        streamQueries = StreamQueryStore();

  /// Database connection that is instantly available, but delegates work to a
  /// connection only available through a `Future`.
  ///
  /// This can be useful in scenarios where you need to obtain a database
  /// instance synchronously, but need an async setup. A prime example here is
  /// `MoorIsolate`:
  ///
  /// ```dart
  /// @UseMoor(...)
  /// class MyDatabase extends _$MyDatabase {
  ///   MyDatabase._connect(DatabaseConnection c): super.connect(c);
  ///
  ///   factory MyDatabase.fromIsolate(MoorIsolate isolate) {
  ///     return MyDatabase._connect(
  ///       // isolate.connect() returns a future, but we can still return a
  ///       // database synchronously thanks to DatabaseConnection.delayed!
  ///       DatabaseConnection.delayed(isolate.connect()),
  ///     );
  ///   }
  /// }
  /// ```
  factory DatabaseConnection.delayed(FutureOr<DatabaseConnection> connection) {
    if (connection is DatabaseConnection) {
      return connection;
    }

    return DatabaseConnection(
      SqlTypeSystem.defaultInstance,
      LazyDatabase(() async => (await connection).executor),
      DelayedStreamQueryStore(connection.then((conn) => conn.streamQueries)),
    );
  }

  /// Returns a database connection that is identical to this one, except that
  /// it uses the provided [executor].
  DatabaseConnection withExecutor(QueryExecutor executor) {
    return DatabaseConnection(typeSystem, executor, streamQueries);
  }
}
