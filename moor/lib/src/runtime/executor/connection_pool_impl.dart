part of 'package:moor/connection_pool.dart';

class _MultiExecutorImpl extends MultiExecutor {
  final QueryExecutor _reads;
  final QueryExecutor _writes;

  _MultiExecutorImpl(this._reads, this._writes) : super._();

  @override
  set databaseInfo(GeneratedDatabase database) {
    super.databaseInfo = database;

    _writes.databaseInfo = database;
    _reads.databaseInfo = _NoMigrationsWrapper(database);
  }

  @override
  Future<bool> ensureOpen() async {
    // note: It's crucial that we open the writes first. The reading connection
    // doesn't run migrations, but has to set the user version.
    await _writes.ensureOpen();
    await _reads.ensureOpen();

    return true;
  }

  @override
  TransactionExecutor beginTransaction() {
    return _writes.beginTransaction();
  }

  @override
  Future<void> runBatched(List<BatchedStatement> statements) async {
    await _writes.runBatched(statements);
  }

  @override
  Future<void> runCustom(String statement, [List args]) async {
    await _writes.runCustom(statement, args);
  }

  @override
  Future<int> runDelete(String statement, List args) async {
    return await _writes.runDelete(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List args) async {
    return await _writes.runInsert(statement, args);
  }

  @override
  Future<List<Map<String, dynamic>>> runSelect(
      String statement, List args) async {
    return await _reads.runSelect(statement, args);
  }

  @override
  Future<int> runUpdate(String statement, List args) async {
    return await _writes.runUpdate(statement, args);
  }

  @override
  Future<void> close() async {
    await _writes.close();
    await _reads.close();
  }
}

// query executors are responsible for starting the migration process on
// a database after they open. We don't want to run migrations twice, so
// we give the reading executor a database handle that doesn't do any
// migrations.
class _NoMigrationsWrapper extends GeneratedDatabase {
  final GeneratedDatabase _inner;

  _NoMigrationsWrapper(this._inner)
      : super(const SqlTypeSystem.withDefaults(), null);

  @override
  Iterable<TableInfo<Table, DataClass>> get allTables => const [];

  @override
  int get schemaVersion => _inner.schemaVersion;

  @override
  Future<void> handleDatabaseCreation({@required SqlExecutor executor}) async {}

  @override
  Future<void> handleDatabaseVersionChange(
      {@required SqlExecutor executor, int from, int to}) async {}

  @override
  Future<void> beforeOpenCallback(
      QueryExecutor executor, OpeningDetails details) async {}
}
