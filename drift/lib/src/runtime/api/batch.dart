part of 'runtime_api.dart';

/// Contains operations to run queries in a batched mode.
///
/// Inside a batch, a set of SQL statements is collected and then run at once.
/// Conceptually, batches are similar to a transaction (and they will use
/// transactions internally).
/// Additionally, batches are very efficient when the same SQL statement is
/// executed with different parameters. Outside of a batch, a new statement
/// would be parsed and prepared for each execution. With batches, statements
/// are only prepared once and then run with the parameters needed.
///
/// This makes batches particularly suitable for bulk updates.
class Batch {
  final List<String> _createdSql = [];
  final Map<String, int> _sqlToIndex = {};
  final List<ArgumentsForBatchedStatement> _createdArguments = [];

  final DatabaseConnectionUser _user;

  /// Whether we should start a transaction when completing.
  final bool _startTransaction;

  final Set<TableUpdate> _createdUpdates = {};

  Batch._(this._user, this._startTransaction);

  void _addUpdate(TableInfo table, UpdateKind kind) {
    _createdUpdates.add(TableUpdate.onTable(table, kind: kind));
  }

  /// Inserts a row constructed from the fields in [row].
  ///
  /// All fields in the entity that don't have a default value or auto-increment
  /// must be set and non-null. Otherwise, an [InvalidDataException] will be
  /// thrown.
  ///
  /// By default, an exception will be thrown if another row with the same
  /// primary key already exists. This behavior can be overridden with [mode],
  /// for instance by using [InsertMode.replace] or [InsertMode.insertOrIgnore].
  ///
  /// [onConflict] can be used to create an upsert clause for engines that
  /// support it. For details and examples, see [InsertStatement.insert].
  ///
  /// See also:
  ///  - [InsertStatement.insert], which would be used outside a [Batch].
  void insert<T extends Table, D>(TableInfo<T, D> table, Insertable<D> row,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) {
    _addUpdate(table, UpdateKind.insert);
    final actualMode = mode ?? InsertMode.insert;
    final context = InsertStatement<T, D>(_user, table)
        .createContext(row, actualMode, onConflict: onConflict);
    _addContext(context);
  }

  /// Inserts all [rows] into the [table].
  ///
  /// All fields in a row that don't have a default value or auto-increment
  /// must be set and non-null. Otherwise, an [InvalidDataException] will be
  /// thrown.
  /// By default, an exception will be thrown if another row with the same
  /// primary key already exists. This behavior can be overridden with [mode],
  /// for instance by using [InsertMode.replace] or [InsertMode.insertOrIgnore].
  /// Using [insertAll] will not disable primary keys or any column constraint
  /// checks.
  /// [onConflict] can be used to create an upsert clause for engines that
  /// support it. For details and examples, see [InsertStatement.insert].
  void insertAll<T extends Table, D>(
      TableInfo<T, D> table, Iterable<Insertable<D>> rows,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) {
    for (final row in rows) {
      insert<T, D>(table, row, mode: mode, onConflict: onConflict);
    }
  }

  /// Equivalent of [InsertStatement.insertOnConflictUpdate] for multiple rows
  /// that will be inserted in this batch.
  void insertAllOnConflictUpdate<T extends Table, D>(
      TableInfo<T, D> table, Iterable<Insertable<D>> rows) {
    for (final row in rows) {
      insert<T, D>(table, row, onConflict: DoUpdate((_) => row));
    }
  }

  /// Writes all present columns from the [row] into all rows in the [table]
  /// that match the [where] clause.
  ///
  /// For more details on how updates work in drift, check out
  /// [UpdateStatement.write] or the [documentation with examples](https://drift.simonbinder.eu/docs/getting-started/writing_queries/#updates-and-deletes)
  void update<T extends Table, D>(TableInfo<T, D> table, Insertable<D> row,
      {Expression<bool> Function(T table)? where}) {
    _addUpdate(table, UpdateKind.update);
    final stmt = UpdateStatement(_user, table);
    if (where != null) stmt.where(where);

    stmt.write(row, dontExecute: true);
    final context = stmt.constructQuery();
    _addContext(context);
  }

  /// Replaces the [row] from the [table] with the updated values. The row in
  /// the table with the same primary key will be replaced.
  ///
  /// See also:
  ///  - [UpdateStatement.replace], which is what would be used outside of a
  ///    [Batch].
  void replace<T extends Table, D>(
    TableInfo<T, D> table,
    Insertable<D> row,
  ) {
    _addUpdate(table, UpdateKind.update);
    final stmt = UpdateStatement(_user, table)..replace(row, dontExecute: true);
    _addContext(stmt.constructQuery());
  }

  /// Helper that calls [replace] for all [rows].
  void replaceAll<T extends Table, D>(
      TableInfo<T, D> table, Iterable<Insertable<D>> rows) {
    for (final row in rows) {
      replace(table, row);
    }
  }

  /// Deletes [row] from the [table] when this batch is executed.
  ///
  /// See also:
  /// - [DatabaseConnectionUser.delete]
  /// - [DeleteStatement.delete]
  void delete<T extends Table, D>(TableInfo<T, D> table, Insertable<D> row) {
    _addUpdate(table, UpdateKind.delete);
    final stmt = DeleteStatement(_user, table)..whereSamePrimaryKey(row);
    _addContext(stmt.constructQuery());
  }

  /// Deletes all rows from [table] matching the provided [filter].
  ///
  /// See also:
  ///  - [DatabaseConnectionUser.delete]
  void deleteWhere<T extends Table, D>(
      TableInfo<T, D> table, Expression<bool> Function(T tbl) filter) {
    _addUpdate(table, UpdateKind.delete);
    final stmt = DeleteStatement(_user, table)..where(filter);
    _addContext(stmt.constructQuery());
  }

  /// Executes the custom [sql] statement with variables instantiated to [args].
  ///
  /// The statement will be added to this batch and executed when the batch
  /// completes. So, this method returns synchronously and it's not possible to
  /// inspect the return value of individual statements.
  ///
  /// See also:
  ///  - [DatabaseConnectionUser.customStatement], the equivalent method outside
  ///    of batches.
  void customStatement(String sql, [List<dynamic>? args]) {
    _addSqlAndArguments(sql, args ?? const []);
  }

  void _addContext(GenerationContext ctx) {
    _addSqlAndArguments(ctx.sql, ctx.boundVariables);
  }

  void _addSqlAndArguments(String sql, List<dynamic> arguments) {
    final stmtIndex = _sqlToIndex.putIfAbsent(sql, () {
      final newIndex = _createdSql.length;
      _createdSql.add(sql);

      return newIndex;
    });

    _createdArguments.add(ArgumentsForBatchedStatement(stmtIndex, arguments));
  }

  Future<void> _commit() async {
    await _user.executor.ensureOpen(_user.attachedDatabase);

    if (_startTransaction) {
      TransactionExecutor? transaction;

      try {
        transaction = _user.executor.beginTransaction();
        await transaction.ensureOpen(_user.attachedDatabase);

        await _runWith(transaction);

        await transaction.send();
      } catch (e) {
        await transaction?.rollback();
        rethrow;
      }
    } else {
      await _runWith(_user.executor);
    }

    _user.notifyUpdates(_createdUpdates);
  }

  Future<void> _runWith(QueryExecutor executor) {
    return executor
        .runBatched(BatchedStatements(_createdSql, _createdArguments));
  }
}
