part of 'runtime_api.dart';

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

  /// A [Type] can't be sent across isolates. Instances of this class shouldn't
  /// be sent over isolates either, so let's keep a reference to a [Type] that
  /// definitely prohibits this.
  // ignore: unused_field
  final Type _$dontSendThisOverIsolates = Null;

  /// Used by generated code
  GeneratedDatabase(SqlTypeSystem types, QueryExecutor executor,
      {StreamQueryStore streamStore})
      : super(types, executor, streamQueries: streamStore) {
    executor?.databaseInfo = this;
  }

  /// Used by generated code to connect to a database that is already open.
  GeneratedDatabase.connect(DatabaseConnection connection)
      : super.fromConnection(connection) {
    connection?.executor?.databaseInfo = this;
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
      QueryExecutor executor, OpeningDetails details) {
    final migration = _resolvedMigration;

    if (migration.beforeOpen != null) {
      return _runEngineZoned(
        BeforeOpenRunner(this, executor),
        () => migration.beforeOpen(details),
      );
    }
    return Future.value();
  }

  /// Closes this database and releases associated resources.
  Future<void> close() async {
    await executor.close();
  }
}
