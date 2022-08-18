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
  GeneratedDatabase(QueryExecutor executor, {StreamQueryStore? streamStore})
      : super(executor, streamQueries: streamStore) {
    assert(_handleInstantiated());
  }

  /// Used by generated code to connect to a database that is already open.
  GeneratedDatabase.connect(DatabaseConnection connection)
      : super.fromConnection(connection) {
    assert(_handleInstantiated());
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
  Future<void> close() async {
    await streamQueries.close();
    await executor.close();

    assert(() {
      if (_openedDbCount[runtimeType] != null) {
        _openedDbCount[runtimeType] = _openedDbCount[runtimeType]! - 1;
      }
      return true;
    }());
  }
}
