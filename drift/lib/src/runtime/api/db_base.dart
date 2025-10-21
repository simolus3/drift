part of 'runtime_api.dart';

/// Keep track of how many databases have been opened for a given database
/// type.
/// We get a number of error reports of "drift not generating tables" that have
/// their origin in users opening multiple instances of their database. This
/// can cause a race conditions when the second [GeneratedDatabase] is opening a
/// underlying [DatabaseConnection] that is already opened but doesn't have the
/// tables created.
Map<Type, int> _openedDbCount = {};

/// A base class for all generated databases.
abstract class GeneratedDatabase extends DatabaseConnectionUser
    implements QueryExecutorUser {
  @override
  GeneratedDatabase get attachedDatabase => this;

  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions();

  /// Specify the schema version of your database. Whenever you change or add
  /// tables, you should bump this field and provide a [migration] strategy.
  ///
  /// The [schemaVersion] must be positive. Typically, one starts with a value
  /// of `1` and increments the value for each modification to the schema.
  @override
  int get schemaVersion;

  /// Defines the migration strategy that will determine how to deal with an
  /// increasing [schemaVersion]. The default value only supports creating the
  /// database by creating all tables known in this database. When you have
  /// changes in your schema, you'll need a custom migration strategy to create
  /// the new tables or change the columns.
  MigrationStrategy get migration => MigrationStrategy();
  MigrationStrategy? _cachedMigration;
  MigrationStrategy get _resolvedMigration => _cachedMigration ??= migration;

  /// The collection of update rules contains information on how updates on
  /// tables result in other updates, for instance due to a trigger.
  ///
  /// There should be no need to overwrite this field, drift will generate an
  /// appropriate implementation automatically.
  StreamQueryUpdateRules get streamUpdateRules =>
      const StreamQueryUpdateRules.none();

  /// A list of tables specified in this database.
  Iterable<TableInfo> get allTables;

  /// A list of all [DatabaseSchemaEntity] that are specified in this database.
  ///
  /// This contains [allTables], but also advanced entities like triggers.
  // return allTables for backwards compatibility
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => allTables;

  /// A [Type] can't be sent across isolates. Instances of this class shouldn't
  /// be sent over isolates either, so let's keep a reference to a [Type] that
  /// definitely prohibits this.
  // ignore: unused_field
  final Type _$dontSendThisOverIsolates = Null;

  /// Used by generated code
  GeneratedDatabase(super.executor, {StreamQueryStore? streamStore})
      : super(streamQueries: streamStore) {
    _whenConstructed();
  }

  /// Used by generated code to connect to a database that is already open.
  GeneratedDatabase.connect(super.connection) : super.fromConnection() {
    _whenConstructed();
  }

  void _whenConstructed() {
    assert(_handleInstantiated());
    devtools.handleCreated(this);
  }

  bool _handleInstantiated() {
    if (!_openedDbCount.containsKey(runtimeType) ||
        driftRuntimeOptions.dontWarnAboutMultipleDatabases) {
      _openedDbCount[runtimeType] = 1;
      return true;
    }

    final count =
        _openedDbCount[runtimeType] = _openedDbCount[runtimeType]! + 1;
    if (count > 1) {
      driftRuntimeOptions.debugPrint(
        'WARNING (drift): It looks like you\'ve created the database class '
        '$runtimeType multiple times. When these two databases use the same '
        'QueryExecutor, race conditions will occur and might corrupt the '
        'database. \n'
        'Try to follow the advice at https://drift.simonbinder.eu/faq/#using-the-database '
        'or, if you know what you\'re doing, set '
        'driftRuntimeOptions.dontWarnAboutMultipleDatabases = true\n'
        'Here is the stacktrace from when the database was opened a second '
        'time:\n${StackTrace.current}\n'
        'This warning will only appear on debug builds.',
      );
    }

    return true;
  }

  /// Creates a [Migrator] with the provided query executor. Migrators generate
  /// sql statements to create or drop tables.
  ///
  /// This api is mainly used internally in drift, especially to implement the
  /// [beforeOpen] callback from the database site.
  /// However, it can also be used if you need to create tables manually and
  /// outside of a [MigrationStrategy]. For almost all use cases, overriding
  /// [migration] should suffice.
  @protected
  @visibleForTesting
  Migrator createMigrator() => Migrator(this);

  @override
  @nonVirtual
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
    return _runConnectionZoned(BeforeOpenRunner(this, executor), () async {
      if (schemaVersion <= 0) {
        throw StateError(
          'The schemaVersion of your database must be positive. \n'
          "A value of zero can't be distinguished from an uninitialized "
          'database, which causes issues in the migrator',
        );
      }

      if (details.wasCreated) {
        final migrator = createMigrator();
        await _resolvedMigration.onCreate(migrator);
      } else if (details.hadUpgrade) {
        final migrator = createMigrator();
        await _resolvedMigration.onUpgrade(
            migrator, details.versionBefore!, details.versionNow);
      }

      await _resolvedMigration.beforeOpen?.call(details);
    });
  }

  /// Closes this database and releases associated resources.
  @override
  Future<void> close() async {
    await super.close();
    devtools.handleClosed(this);

    assert(() {
      if (_openedDbCount[runtimeType] != null) {
        _openedDbCount[runtimeType] = _openedDbCount[runtimeType]! - 1;
      }
      return true;
    }());
  }

  /// On native platforms this spawns a short-lived isolate to run the [computation] with a drift
  /// database.
  /// On web platforms, this will run the [computation] on the current JavaScript context.
  ///
  /// Essentially, this is a variant of [Isolate.run] for computations that also
  /// need to share a drift database between them. As drift databases are
  /// stateful objects, they can't be send across isolates (and thus used in
  /// [Isolate.run] or Flutter's `compute`) without special setup.
  ///
  /// This method will extract the underlying database connection of `this`
  /// database into a form that can be serialized across isolates. Then,
  /// [Isolate.run] will be called to invoke [computation]. The [connect]
  /// function is responsible for creating an instance of your database class
  /// from the low-level connection.
  ///
  /// As an example, consider a database class:
  ///
  /// ```dart
  /// class MyDatabase extends $MyDatabase {
  ///   MyDatabase(QueryExecutor executor): super(executor);
  /// }
  /// ```
  ///
  /// [computeWithDatabase] can then be used to access an instance of
  /// `MyDatabase` in a new isolate, even though `MyDatabase` is not generally
  /// sharable between isolates:
  ///
  /// ```dart
  /// Future<void> loadBulkData(MyDatabase db) async {
  ///   await db.computeWithDatabase(
  ///     connect: MyDatabase.new,
  ///     computation: (db) async {
  ///       // This computation has access to a second `db` that is internally
  ///       // linked to the original database.
  ///       final data = await fetchRowsFromNetwork();
  ///       await db.batch((batch) {
  ///         // More expensive work like inserting data
  ///       });
  ///     },
  ///   );
  /// }
  /// ```
  ///
  /// Note that with the recommended setup of `NativeDatabase.createInBackground`,
  /// drift will already use an isolate to run your SQL statements. Using
  /// [computeWithDatabase] is beneficial when an an expensive work unit needs
  /// to use the database, or when creating the SQL statements itself is
  /// expensive.
  /// In particular, note that [computeWithDatabase] does not create a second
  /// database connection to sqlite3 - the current one is re-used. So if you're
  /// using a synchronous database connection, using this method is unlikely to
  /// take significant loads off the main isolate. For that reason, the use of
  /// `NativeDatabase.createInBackground` is encouraged.
  Future<Ret> computeWithDatabase<Ret, DB extends GeneratedDatabase>({
    required FutureOr<Ret> Function(DB) computation,
    required DB Function(DatabaseConnection) connect,
  }) =>
      computeWithDatabaseImplementation(
          computation: computation, connect: connect, database: this as DB);
}
