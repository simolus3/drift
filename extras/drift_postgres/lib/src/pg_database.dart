import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/backends.dart';
import 'package:postgres/postgres_v3_experimental.dart';

/// A drift database implementation that talks to a postgres database.
class PgDatabase extends DelegatedDatabase {
  PgDatabase({
    required PgEndpoint endpoint,
    PgSessionSettings? sessionSettings,
    bool logStatements = false,
  }) : super(
          _PgDelegate(
            () => PgConnection.open(endpoint, sessionSettings: sessionSettings),
            true,
          ),
          isSequential: true,
          logStatements: logStatements,
        );

  /// Creates a drift database implementation from a postgres database
  /// [connection].
  PgDatabase.opened(PgSession connection, {bool logStatements = false})
      : super(_PgDelegate(() => connection, false),
            isSequential: true, logStatements: logStatements);

  @override
  SqlDialect get dialect => SqlDialect.postgres;
}

class _PgDelegate extends DatabaseDelegate {
  _PgDelegate(this._open, this.closeUnderlyingWhenClosed);

  final bool closeUnderlyingWhenClosed;
  final FutureOr<PgSession> Function() _open;

  PgSession? _openedSession;

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  late DbVersionDelegate versionDelegate;

  @override
  Future<bool> get isOpen => Future.value(_openedSession != null);

  @override
  Future<void> open(QueryExecutorUser user) async {
    final session = await _open();
    final pgVersionDelegate = _PgVersionDelegate(session);

    await pgVersionDelegate.init();

    _openedSession = session;
    versionDelegate = pgVersionDelegate;
  }

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    final session = _openedSession!;
    final prepared = <PgStatement>[];

    try {
      for (final statement in statements.statements) {
        prepared.add(await session.prepare(PgSql(statement)));
      }

      for (final row in statements.arguments) {
        final stmt = prepared[row.statementIndex];

        await stmt.run(row.arguments);
      }
    } finally {
      for (final stmt in prepared) {
        await stmt.dispose();
      }
    }
  }

  Future<int> _runWithArgs(String statement, List<Object?> args) async {
    final session = _openedSession!;

    final result = await session.execute(PgSql(statement), parameters: args);
    return result.affectedRows;
  }

  @override
  Future<void> runCustom(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    final session = _openedSession!;
    final result = await session.execute(PgSql(statement), parameters: args);
    return result.firstOrNull?[0] as int? ?? 0;
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    return _runWithArgs(statement, args);
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    final session = _openedSession!;
    final result = await session.execute(PgSql(statement), parameters: args);

    return QueryResult([
      for (final pgColumn in result.schema.columns) pgColumn.columnName ?? '',
    ], result);
  }

  @override
  Future<void> close() async {
    if (closeUnderlyingWhenClosed) {
      await _openedSession?.close();
    }
  }

  Object? _convertValue(Object? value) {
    if (value is BigInt) {
      return value.toInt();
    }
    return value;
  }
}

class _PgVersionDelegate extends DynamicVersionDelegate {
  final PgSession database;

  _PgVersionDelegate(this.database);

  @override
  Future<int> get schemaVersion async {
    final result =
        await database.execute(PgSql('SELECT version FROM __schema'));
    return result[0][0] as int;
  }

  Future init() async {
    await database.execute(PgSql('CREATE TABLE IF NOT EXISTS __schema ('
        'version integer NOT NULL DEFAULT 0)'));

    final count =
        await database.execute(PgSql('SELECT COUNT(*) FROM __schema'));
    if (count[0][0] as int == 0) {
      await database
          .execute(PgSql('INSERT INTO __schema (version) VALUES (0)'));
    }
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    await database.execute(
      PgSql(r'UPDATE __schema SET version = $1', types: [PgDataType.integer]),
      parameters: [
        PgTypedParameter(PgDataType.integer, version),
      ],
    );
  }
}
