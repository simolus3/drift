part of 'runtime_api.dart';

/// Contains operations to run queries in a batched mode. This can be much more
/// efficient when running a lot of similar queries at the same time, making
/// this api suitable for bulk updates.
class Batch {
  final Map<String, List<List<dynamic>>> _createdStatements = {};
  final QueryEngine _engine;

  /// Whether we should start a transaction when completing.
  final bool _startTransaction;

  final Set<TableUpdate> _createdUpdates = {};

  Batch._(this._engine, this._startTransaction);

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
  /// See also:
  ///  - [InsertStatement.insert], which would be used outside a [Batch].
  void insert<D extends DataClass>(TableInfo<Table, D> table, Insertable<D> row,
      {InsertMode mode}) {
    _addUpdate(table, UpdateKind.insert);
    final actualMode = mode ?? InsertMode.insert;
    final context = InsertStatement<Table, D>(_engine, table)
        .createContext(row, actualMode);
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
  void insertAll<D extends DataClass>(
      TableInfo<Table, D> table, List<Insertable<D>> rows,
      {InsertMode mode}) {
    for (final row in rows) {
      insert<D>(table, row, mode: mode);
    }
  }

  /// Writes all present columns from the [row] into all rows in the [table]
  /// that match the [where] clause.
  ///
  /// For more details on how updates work in moor, check out
  /// [UpdateStatement.write] or the [documentation with examples](https://moor.simonbinder.eu/docs/getting-started/writing_queries/#updates-and-deletes)
  void update<T extends Table, D extends DataClass>(
      TableInfo<T, D> table, Insertable<D> row,
      {Expression<bool> Function(T table) where}) {
    _addUpdate(table, UpdateKind.update);
    final stmt = UpdateStatement(_engine, table);
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
  void replace<T extends Table, D extends DataClass>(
    TableInfo<T, D> table,
    Insertable<D> row,
  ) {
    _addUpdate(table, UpdateKind.update);
    final stmt = UpdateStatement(_engine, table)
      ..replace(row, dontExecute: true);
    _addContext(stmt.constructQuery());
  }

  /// Helper that calls [replace] for all [rows].
  void replaceAll<T extends Table, D extends DataClass>(
      TableInfo<T, D> table, List<Insertable<D>> rows) {
    for (final row in rows) {
      replace(table, row);
    }
  }

  /// Deletes [row] from the [table] when this batch is executed.
  ///
  /// See also:
  /// - [QueryEngine.delete]
  /// - [DeleteStatement.delete]
  void delete<T extends Table, D extends DataClass>(
      TableInfo<T, D> table, Insertable<D> row) {
    _addUpdate(table, UpdateKind.delete);
    final stmt = DeleteStatement(_engine, table)..whereSamePrimaryKey(row);
    _addContext(stmt.constructQuery());
  }

  /// Deletes all rows from [table] matching the provided [filter].
  ///
  /// See also:
  ///  - [QueryEngine.delete]
  void deleteWhere<T extends Table, D extends DataClass>(
      TableInfo<T, D> table, Expression<bool> Function(T tbl) filter) {
    _addUpdate(table, UpdateKind.delete);
    final stmt = DeleteStatement(_engine, table)..where(filter);
    _addContext(stmt.constructQuery());
  }

  void _addContext(GenerationContext ctx) {
    final sql = ctx.sql;
    final variableSet = _createdStatements.putIfAbsent(sql, () => []);
    variableSet.add(ctx.boundVariables);
  }

  Future<void> _commit() async {
    await _engine.executor.ensureOpen(_engine.attachedDatabase);

    if (_startTransaction) {
      TransactionExecutor transaction;

      try {
        transaction = _engine.executor.beginTransaction();
        await transaction.ensureOpen(null);

        await _runWith(transaction);

        await transaction.send();
      } catch (e) {
        await transaction.rollback();
        rethrow;
      }
    } else {
      await _runWith(_engine.executor);
    }

    _engine.notifyUpdates(_createdUpdates);
  }

  Future<void> _runWith(QueryExecutor executor) async {
    final statements = _createdStatements.entries.map((entry) {
      return BatchedStatement(entry.key, entry.value);
    }).toList();

    await executor.runBatched(statements);
  }
}
