import 'dart:async';

import 'package:drift/backends.dart';
import 'package:mysql_client/mysql_client.dart';

/// A drift database implementation that talks to a mariadb database.
class MariaDBDatabase extends DelegatedDatabase {
  MariaDBDatabase({
    required MySQLConnectionPool pool,
    bool isSequential = true,
    bool logStatements = false,
  }) : super(
          _MariaDelegate(() => pool, true),
          isSequential: isSequential,
          logStatements: logStatements,
        );

  /// Creates a drift database implementation from a mariadb database
  /// [connection].
  MariaDBDatabase.opened(
    MySQLConnectionPool connection, {
    bool logStatements = false,
  }) : super(
          _MariaDelegate(() => connection, false),
          isSequential: true,
          logStatements: logStatements,
        );

  @override
  SqlDialect get dialect => SqlDialect.mariadb;
}

class _MariaDelegate extends DatabaseDelegate {
  _MariaDelegate(this._open, this.closeUnderlyingWhenClosed);

  final bool closeUnderlyingWhenClosed;
  final FutureOr<MySQLConnectionPool> Function() _open;

  MySQLConnectionPool? _openedSession;

  @override
  TransactionDelegate get transactionDelegate => NoTransactionDelegate(
        start: 'START TRANSACTION',
        commit: 'COMMIT',
        rollback: 'ROLLBACK',
        savepoint: (int depth) => 'SAVEPOINT s$depth',
        release: (int depth) => 'RELEASE SAVEPOINT s$depth',
        rollbackToSavepoint: (int depth) => 'ROLLBACK TO SAVEPOINT s$depth',
      );

  @override
  late DbVersionDelegate versionDelegate;

  @override
  Future<bool> get isOpen => Future.value(_openedSession != null);

  @override
  Future<void> open(QueryExecutorUser user) async {
    final session = await _open();
    final mariaVersionDelegate = _MariaVersionDelegate(session);

    await mariaVersionDelegate.init();

    _openedSession = session;
    versionDelegate = mariaVersionDelegate;
  }

  @override
  Future<void> runBatched(BatchedStatements statements) async {
    final session = _openedSession!;
    final prepared = List<PreparedStmt?>.filled(
      statements.statements.length,
      null,
    );

    try {
      for (final instantiation in statements.arguments) {
        final mariaArgs = _BoundArguments.ofDartArgs(instantiation.arguments);
        final stmtIndex = instantiation.statementIndex;
        var stmt = prepared[stmtIndex];
        final sql = statements.statements[stmtIndex];
        stmt ??= prepared[stmtIndex] = await session.prepare(sql);
        await stmt.execute(mariaArgs.parameters);
      }
    } finally {
      for (var stmt in prepared) {
        stmt?.deallocate();
      }
    }
  }

  Future<int> _runWithArgs(String statement, List<Object?> args) async {
    final session = _openedSession!;

    IResultSet result;
    if (args.isEmpty) {
      result = await session.execute(statement);
    } else {
      var mariaArgs = _BoundArguments.ofDartArgs(args);
      var stmt = await session.prepare(statement);
      result = await stmt.execute(mariaArgs.parameters);
    }
    return result.affectedRows.toInt();
  }

  @override
  Future<void> runCustom(String statement, List<Object?> args) async {
    await _runWithArgs(statement, args);
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    final session = _openedSession!;

    IResultSet result;
    if (args.isEmpty) {
      result = await session.execute(statement);
    } else {
      var mariaArgs = _BoundArguments.ofDartArgs(args);
      var stmt = await session.prepare(statement);

      result = await stmt.execute(mariaArgs.parameters);
    }

    return result.firstOrNull?.lastInsertID.toInt() ?? 0;
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    return _runWithArgs(statement, args);
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    var session = _openedSession!;
    IResultSet result;
    if (args.isEmpty) {
      result = await session.execute(statement);
    } else {
      var mariaArgs = _BoundArguments.ofDartArgs(args);
      var stmt = await session.prepare(statement);
      result = await stmt.execute(mariaArgs.parameters);
    }
    print(statement);
    var rowsList = result.rows.toList();
    var rowsParsed = List.generate(
      rowsList.length,
      (index) => rowsList[index].typedAssoc().values.toList(),
    );

    return QueryResult(
      [for (final mariaColumn in result.cols) mariaColumn.name],
      rowsParsed,
    );
  }

  @override
  Future<void> close() async {
    if (closeUnderlyingWhenClosed) {
      await _openedSession?.close();
    }
  }
}

class _BoundArguments {
  final List<Object?> parameters;

  _BoundArguments(this.parameters);

  factory _BoundArguments.ofDartArgs(List<Object?> args) {
    final parameters = <Object?>[];

    void add(Object? param) {
      parameters.add(param);
    }

    for (final value in args) {
      if (value == null) {
        add(null);
      } else if (value is int) {
        add(value);
      } else if (value is BigInt) {
        add(value);
      } else if (value is bool) {
        add(value ? 1 : 0);
      } else if (value is double) {
        add(value);
      } else if (value is String) {
        add(value);
      } else {
        throw ArgumentError.value(value, 'value', 'Unsupported type');
      }
    }

    return _BoundArguments(parameters);
  }
}

class _MariaVersionDelegate extends DynamicVersionDelegate {
  final MySQLConnectionPool database;

  _MariaVersionDelegate(this.database);

  @override
  Future<int> get schemaVersion async {
    final result = await database.execute('SELECT version FROM __schema');
    return result.rows.first.typedAssoc()['version'] as int;
  }

  Future init() async {
    await database.execute('CREATE TABLE IF NOT EXISTS __schema (version '
        'integer NOT NULL DEFAULT 0)');

    final count = await database.execute('SELECT COUNT(*) FROM __schema');
    if (count.rows.first.typedAssoc()['COUNT(*)'] as int == 0) {
      await database.execute('INSERT INTO __schema (version) VALUES (0)');
    }
  }

  @override
  Future<void> setSchemaVersion(int version) async {
    var stmt = await database.prepare(r'UPDATE __schema SET version = (?)');
    await stmt.execute([version]);
  }
}
