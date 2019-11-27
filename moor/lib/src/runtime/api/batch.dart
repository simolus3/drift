part of 'runtime_api.dart';

/// Contains operations to run queries in a batched mode. This can be much more
/// efficient when running a lot of similar queries at the same time, making
/// this api suitable for bulk updates.
class Batch {
  final Map<String, List<List<dynamic>>> _createdStatements = {};
  final QueryEngine _engine;

  final Set<TableInfo> _affectedTables = {};

  Batch._(this._engine);

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
    _affectedTables.add(table);
    final actualMode = mode ?? InsertMode.insert;
    final context =
        InsertStatement<D>(_engine, table).createContext(row, actualMode);
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
    for (var row in rows) {
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
      {Expression<bool, BoolType> Function(T table) where}) {
    _affectedTables.add(table);
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
    _affectedTables.add(table);
    final stmt = UpdateStatement(_engine, table)
      ..replace(row, dontExecute: true);
    _addContext(stmt.constructQuery());
  }

  /// Helper that calls [replace] for all [rows].
  void replaceAll<T extends Table, D extends DataClass>(
      TableInfo<T, D> table, List<Insertable<D>> rows) {
    for (var row in rows) {
      replace(table, row);
    }
  }

  void _addContext(GenerationContext ctx) {
    final sql = ctx.sql;
    final variableSet = _createdStatements.putIfAbsent(sql, () => []);
    variableSet.add(ctx.boundVariables);
  }

  Future<void> _commit() async {
    await _engine.executor.ensureOpen();

    final transaction = _engine.executor.beginTransaction();
    await transaction.doWhenOpened((executor) async {
      final statements = _createdStatements.entries.map((entry) {
        return BatchedStatement(entry.key, entry.value);
      }).toList();
      await executor.runBatched(statements);
    });
    await transaction.send();
    _engine.markTablesUpdated(_affectedTables);
  }
}
