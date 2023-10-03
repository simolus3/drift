import 'package:drift/backends.dart';
import 'package:drift/drift.dart';
import 'package:drift/src/runtime/executor/stream_queries.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

export 'database_stub.dart'
    if (dart.library.ffi) 'database_vm.dart'
    if (dart.library.js) 'database_web.dart';
export 'matchers.dart';
export 'mocks.dart';

@GenerateNiceMocks([
  MockSpec<DatabaseDelegate>(),
  MockSpec<DynamicVersionDelegate>(),
  MockSpec<SupportedTransactionDelegate>(),
  MockSpec<StreamQueryStore>(as: #MockStreamQueries),
])
export 'test_utils.mocks.dart';

class CustomQueryExecutorUser extends QueryExecutorUser {
  @override
  final int schemaVersion;

  Future<void> Function(
    QueryExecutorUser self,
    QueryExecutor executor,
    OpeningDetails details,
  ) beforeOpenCallback;

  CustomQueryExecutorUser(
      {required this.schemaVersion, required this.beforeOpenCallback});

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
    return beforeOpenCallback(this, executor, details);
  }
}

DatabaseConnection createConnection(QueryExecutor executor,
    [StreamQueryStore? streams]) {
  return DatabaseConnection(executor,
      streamQueries: streams ?? StreamQueryStore());
}

GenerationContext stubContext({
  DriftDatabaseOptions? options,
  SqlDialect dialect = SqlDialect.sqlite,
}) {
  final warnBefore = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final database = _NullDatabase(_NullExecutor(dialect: dialect));
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = warnBefore;

  return GenerationContext(options ?? const DriftDatabaseOptions(), database);
}

class _NullDatabase extends GeneratedDatabase {
  _NullDatabase([QueryExecutor? e]) : super(e ?? _NullExecutor());

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables =>
      throw UnsupportedError('stub');

  @override
  int get schemaVersion => throw UnsupportedError('stub!');
}

class _NullExecutor extends Fake implements QueryExecutor {
  @override
  final SqlDialect dialect;

  _NullExecutor({this.dialect = SqlDialect.sqlite});
}

class CustomTable extends Table with TableInfo<CustomTable, void> {
  @override
  final String actualTableName;
  @override
  final DatabaseConnectionUser attachedDatabase;
  final List<GeneratedColumn<Object>> columns;
  final String? _alias;

  CustomTable(this.actualTableName, this.attachedDatabase, this.columns,
      [this._alias]);

  @override
  List<GeneratedColumn<Object>> get $columns => columns;

  @override
  String get aliasedName => _alias ?? actualTableName;

  @override
  CustomTable createAlias(String alias) {
    return CustomTable(actualTableName, attachedDatabase, columns, alias);
  }

  @override
  Future<void> map(Map<String, dynamic> data, {String? tablePrefix}) async {
    return;
  }
}
