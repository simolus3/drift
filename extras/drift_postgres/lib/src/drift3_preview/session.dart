import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
// ignore: implementation_imports
import 'package:drift/src/drift3_preview/drift.dart';
import 'package:postgres/postgres.dart';

import 'type.dart';

abstract base class _BasePostgresSession implements DriftSession {
  final Session _session;

  _BasePostgresSession(this._session);

  @override
  Future<QueryResult> execute(StatementInfo statement) async {
    final parameters = statement.variables.map((e) => e as TypedValue).toList();
    final result = await _session.execute(
      statement.sql,
      parameters: parameters,
      ignoreRows: !statement.needsResultSet,
    );

    return _mapResult(statement, result);
  }

  @override
  Future<List<QueryResult>> executeBatch(StatementBatch batch) async {
    final prepared = await Future.wait(batch.sql.map(_session.prepare));

    final results = <QueryResult>[];
    for (final instr in batch.statements) {
      final stmt = prepared[instr.sqlIndex];
      final parameters = instr.info.variables
          .map((e) => e as TypedValue)
          .toList();

      final result = await stmt.run(parameters);
      results.add(_mapResult(instr.info, result));
    }

    return results;
  }

  QueryResult _mapResult(StatementInfo statement, Result result) {
    var lastInsertRowId = -1;
    // Postgres doesn't have a last_insert_rowid, but if there's a serial pk
    // then we generate an implicit returning clause for this.
    if (result.length == 1 && result.schema.columns.length == 1) {
      final value = result[0][0];
      if (value is int) lastInsertRowId = value;
    }

    return QueryResult(
      resultSet: statement.needsResultSet ? _PostgresResultSet(result) : null,
      affectedRows: result.affectedRows,
      lastInsertRowId: lastInsertRowId,
    );
  }

  @override
  DriftSessionWithInternalLocks? get locks => null;

  @override
  Object? get tag => null;

  @override
  Future<void> get closed => _session.closed;

  @override
  bool get isClosed => !_session.isOpen;
}

/// A drift database implementation that talks to a postgres database.
final class PostgresSession extends _BasePostgresSession
    implements DriftTransactionParent {
  final SessionExecutor _connection;
  final bool _enableMigrations;

  /// Wraps an opened [Connection] as a drift implementation.
  ///
  /// The connection will be closed when this database is closed.
  PostgresSession(
    Connection super._session, {

    /// Enable migrations on this database.
    bool enableMigrations = true,
  }) : _connection = _session,
       _enableMigrations = enableMigrations;

  /// Opens a [PostgresSession] by calling [Connection.open].
  static Future<PostgresSession> open(
    Endpoint endpoint, {
    ConnectionSettings? settings,
  }) async {
    return PostgresSession(await Connection.open(endpoint, settings: settings));
  }

  @override
  Future<void> close() async {
    await _connection.close();
  }

  @override
  PersistentSchemaVersion? get persistentSchemaVersion =>
      _enableMigrations ? _PgVersionDelegate(_session) : null;

  @override
  DriftTransactionSession? get transaction => null;

  @override
  DriftTransactionParent? get transactionParent => this;

  @override
  Future<DriftSession> begin(TransactionOptions options) async {
    final transactionStarted = Completer<DriftSession>();

    _connection
        .runTx((tx) async {
          final session = _TransactionSession(tx);
          transactionStarted.complete(session);

          await session._closedInner.future;
        })
        // Ensure we don't return without completing the transactionStarted
        // completer.
        .then(
          (_) {
            if (!transactionStarted.isCompleted) {
              transactionStarted.completeError(
                StateError('Transaction never started'),
              );
            }
          },
          onError: (Object e, StackTrace s) {
            if (!transactionStarted.isCompleted) {
              transactionStarted.completeError(e, s);
            }
          },
        );

    return await transactionStarted.future;
  }
}

final class _TransactionSession extends _BasePostgresSession
    implements DriftTransactionSession {
  final TxSession _tx;
  final Completer<void> _closedInner = Completer();

  _TransactionSession(this._tx) : super(_tx);

  @override
  Future<void> commit() => close();

  @override
  Future<void> rollback() async {
    await _tx.rollback();
    return close();
  }

  @override
  Future<void> close() {
    _closedInner.complete();
    return closed;
  }

  @override
  PersistentSchemaVersion? get persistentSchemaVersion => null;

  @override
  DriftTransactionSession? get transaction => this;

  @override
  DriftTransactionParent? get transactionParent => null;
}

final class _PgVersionDelegate implements PersistentSchemaVersion {
  final Session database;

  final Completer<void> _init = Completer();

  _PgVersionDelegate(this.database);

  Future<void> _waitInitialized() {
    if (!_init.isCompleted) {
      _init.complete(_initialize());
    }

    return _init.future;
  }

  Future<void> _initialize() async {
    await database.execute(
      Sql(
        'CREATE TABLE IF NOT EXISTS __schema ('
        'version integer NOT NULL DEFAULT 0)',
      ),
    );

    final count = await database.execute(Sql('SELECT COUNT(*) FROM __schema'));
    if (count[0][0] as int == 0) {
      await database.execute(Sql('INSERT INTO __schema (version) VALUES (0)'));
    }
  }

  @override
  Future<int> get schemaVersion async {
    await _waitInitialized();

    final result = await database.execute(Sql('SELECT version FROM __schema'));
    return result[0][0] as int;
  }

  @override
  Future<void> writeSchemaVersion(int version) async {
    await _waitInitialized();

    await database.execute(
      Sql(r'UPDATE __schema SET version = $1', types: [Type.integer]),
      parameters: [TypedValue(Type.integer, version)],
    );
  }
}

final class _PostgresResultSet extends RawResultSet {
  final Result _result;

  _PostgresResultSet(this._result)
    : super(
        columnNames: [
          for (final column in _result.schema.columns) column.columnName ?? '',
        ],
      );

  @override
  int get length => _result.length;

  @override
  RawRow operator [](int index) {
    final sourceRow = _result[index];
    return _PostgresRow(sourceRow);
  }
}

final class _PostgresRow
    with ListMixin<Object?>, NonGrowableListMixin<Object?>
    implements RawRow {
  final ResultRow _postgresRow;

  _PostgresRow(this._postgresRow);

  @override
  Object? operator [](int index) {
    if (_postgresRow.isSqlNull(index)) {
      return null;
    }

    return PostgresDatabaseValue(
      column: _postgresRow.schema.columns[index],
      value: _postgresRow[index],
    );
  }

  @override
  void operator []=(int index, Object? value) {
    throw UnsupportedError('Modifying postgres row');
  }

  @override
  int get length => _postgresRow.length;
}
