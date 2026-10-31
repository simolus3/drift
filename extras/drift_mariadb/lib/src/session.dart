import 'dart:async';

import 'package:drift3_preview/drift.dart';
import 'package:mysql_client/mysql_client.dart';

/// A [DriftSession] backed by a [MySQLConnectionPool].
final class MariaDbSession implements DriftSession {
  final MySQLConnectionPool _pool;

  final Completer<void> _close = Completer();

  @override
  late final PersistentSchemaVersion? persistentSchemaVersion;

  MariaDbSession(this._pool, bool enableMigrations) {
    persistentSchemaVersion = enableMigrations
        ? _MariaVersionDelegate(this)
        : null;
  }

  @override
  Future<QueryResult> execute(
    StatementInfo statement, {
    AbortToken? abort,
  }) async {
    final IResultSet result;

    if (statement.variables.isEmpty) {
      result = await _pool.execute(statement.sql);
    } else {
      final stmt = await _pool.prepare(statement.sql);
      result = await stmt.execute(statement.variables);
    }

    return result.toDriftResult();
  }

  @override
  Future<List<QueryResult>> executeBatch(
    StatementBatch batch, {
    AbortToken? abort,
  }) async {
    final prepared = List<PreparedStmt?>.filled(batch.sql.length, null);
    final results = <QueryResult>[];

    try {
      for (final instantiation in batch.statements) {
        final stmtIndex = instantiation.sqlIndex;
        var stmt = prepared[stmtIndex];
        stmt ??= prepared[stmtIndex] = await _pool.prepare(
          batch.sql[stmtIndex],
        );

        results.add(
          (await stmt.execute(instantiation.info.variables)).toDriftResult(),
        );
      }
    } finally {
      for (var stmt in prepared) {
        stmt?.deallocate();
      }
    }

    return results;
  }

  @override
  bool get isClosed => _close.isCompleted;

  @override
  Future<void> get closed => _close.future;

  @override
  Future<void> close() {
    if (!_close.isCompleted) {
      _close.complete(_pool.close());
    }
    return closed;
  }

  @override
  DriftSessionWithInternalLocks? get locks => null;

  @override
  Object? get tag => null;

  @override
  DriftTransactionSession? get transaction => null;

  @override
  DriftTransactionParent? get transactionParent => null;
}

final class _MariaVersionDelegate implements PersistentSchemaVersion {
  final MariaDbSession session;
  final Completer<void> _initialized = Completer();

  _MariaVersionDelegate(this.session);

  Future<void> _ensureInitialized() {
    if (!_initialized.isCompleted) {
      _initialized.complete(_initialize());
    }

    return _initialized.future;
  }

  Future<void> _initialize() async {
    final database = session._pool;
    await database.execute(
      'CREATE TABLE IF NOT EXISTS __schema (version '
      'integer NOT NULL DEFAULT 0)',
    );

    final count = await database.execute('SELECT COUNT(*) FROM __schema');
    if (count.rows.first.typedAssoc()['COUNT(*)'] as int == 0) {
      await database.execute('INSERT INTO __schema (version) VALUES (0)');
    }
  }

  @override
  Future<int> get schemaVersion async {
    await _ensureInitialized();
    final result = await session._pool.execute('SELECT version FROM __schema');
    return result.rows.first.typedAssoc()['version'] as int;
  }

  @override
  Future<void> writeSchemaVersion(int version) async {
    await _ensureInitialized();
    var stmt = await session._pool.prepare(
      r'UPDATE __schema SET version = (?)',
    );
    await stmt.execute([version]);
  }
}

extension on IResultSet {
  QueryResult toDriftResult() {
    return QueryResult(
      resultSet: RawResultSet.fromRows(
        columnNames: [for (final col in cols) col.name],
        rows: [
          for (final row in rows)
            [for (var i = 0; i < row.numOfColumns; i++) row.colAt(i)],
        ],
      ),
      lastInsertRowId: lastInsertID.toInt(),
      affectedRows: affectedRows.toInt(),
    );
  }
}
