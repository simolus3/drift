import 'package:collection/collection.dart';
import 'package:drift/backends.dart';
import 'package:postgres/postgres.dart';

/// A drift database implementation that talks to a postgres database.
class PgDatabase extends DelegatedDatabase {
  /// Creates a drift database implementation from a postgres database
  /// [connection].
  PgDatabase(PostgreSQLConnection connection)
      : super(_PgDelegate(connection, connection),
            isSequential: true, logStatements: true);

  @override
  SqlDialect get dialect => SqlDialect.postgres;
}

class _PgDelegate extends DatabaseDelegate {
  final PostgreSQLConnection _db;
  final PostgreSQLExecutionContext _ec;

  _PgDelegate(this._db, this._ec) : closeUnderlyingWhenClosed = false;

  bool _isOpen = false;

  final bool closeUnderlyingWhenClosed;

  @override
  TransactionDelegate get transactionDelegate => _PgTransactionDelegate(_db);

  @override
  late DbVersionDelegate versionDelegate;

  @override
  Future<bool> get isOpen => Future.value(_isOpen);

  @override
  Future<void> open(QueryExecutorUser user) async {
    final pgVersionDelegate = _PgVersionDelegate(_db);

    await _db.open();
    await pgVersionDelegate.init();

    versionDelegate = pgVersionDelegate;
    _isOpen = true;
  }

  Future _ensureOpen() async {
    if (_db.isClosed) {
      await _db.open();
    }
  }

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    await _ensureOpen();

    for (final row in statements.arguments) {
      final stmt = statements.statements[row.statementIndex];
      final args = row.arguments;

      await _ec.execute(stmt,
          substitutionValues: args
              .asMap()
              .map((key, value) => MapEntry((key + 1).toString(), value)));
    }

    return Future.value();
  }

  Future<int> _runWithArgs(String statement, List<Object?> args) async {
    await _ensureOpen();

    if (args.isEmpty) {
      return _ec.execute(statement);
    } else {
      return _ec.execute(statement,
          substitutionValues: args
              .asMap()
              .map((key, value) => MapEntry((key + 1).toString(), value)));
    }
  }

  @override
  Future<void> runCustom(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    await _ensureOpen();
    PostgreSQLResult result;
    if (args.isEmpty) {
      result = await _ec.query(statement);
    } else {
      result = await _ec.query(statement,
          substitutionValues: args
              .asMap()
              .map((key, value) => MapEntry((key + 1).toString(), value)));
    }
    return result.firstOrNull?[0] as int? ?? 0;
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    return _runWithArgs(statement, args);
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    await _ensureOpen();
    final result = await _ec.query(statement,
        substitutionValues: args
            .asMap()
            .map((key, value) => MapEntry((key + 1).toString(), value)));

    return Future.value(QueryResult.fromRows(
        result.map((e) => e.toColumnMap()).toList(growable: false)));
  }

  @override
  Future<void> close() async {
    if (closeUnderlyingWhenClosed) {
      await _db.close();
    }
  }
}

class _PgVersionDelegate extends DynamicVersionDelegate {
  final PostgreSQLConnection database;

  _PgVersionDelegate(this.database);

  @override
  Future<int> get schemaVersion async {
    final result = await database.query('SELECT version FROM __schema');
    return result[0][0] as int;
  }

  Future init() async {
    await database.query('CREATE TABLE IF NOT EXISTS __schema ('
        'version integer NOT NULL DEFAULT 0)');
    final count = await database.query('SELECT COUNT(*) FROM __schema');
    if (count[0][0] as int == 0) {
      await database.query('INSERT INTO __schema (version) VALUES (0)');
    }
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    await database.query('UPDATE __schema SET version = @1',
        substitutionValues: {'1': version});
  }
}

class _PgTransactionDelegate extends WrappedTransactionDelegate {
  final PostgreSQLConnection _db;

  const _PgTransactionDelegate(this._db);

  @override
  Future runInTransaction(Future Function(QueryDelegate p1) run) async {
    await _db.transaction((connection) => run(_PgDelegate(_db, connection)));
  }
}
