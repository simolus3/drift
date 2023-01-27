import 'package:drift/drift.dart';

/// Easily-accessible methods to compose common operations or statements on
/// tables or views.
extension TableOrViewStatements<Tbl extends HasResultSet, Row>
    on ResultSetImplementation<Tbl, Row> {
  /// Selects all rows that are in this table.
  ///
  /// The returned [Selectable] can be run once as a future with [Selectable.get]
  /// or as an auto-updating stream with [Selectable.watch].
  Selectable<Row> all() {
    return select();
  }

  /// Composes a `SELECT` statement on the captured table or view.
  ///
  /// This is equivalent to calling [DatabaseConnectionUser.select].
  SimpleSelectStatement<Tbl, Row> select({bool distinct = false}) {
    return attachedDatabase.select(this, distinct: distinct);
  }

  /// Composes a `SELECT` statement only selecting a subset of columns.
  ///
  /// This is equivalent to calling [DatabaseConnectionUser.selectOnly].
  JoinedSelectStatement<Tbl, Row> selectOnly({bool distinct = false}) {
    return attachedDatabase.selectOnly(this, distinct: distinct);
  }
}

/// Easily-accessible methods to compose common operations or statements on
/// tables.
extension TableStatements<Tbl extends Table, Row> on TableInfo<Tbl, Row> {
  /// Creates an insert statment to be used to compose an insert on the table.
  ///
  /// This is equivalent to calling [DatabaseConnectionUser.into] on the
  /// captured table. See that method for more information.
  InsertStatement<Tbl, Row> insert() => attachedDatabase.into(this);

  /// Inserts one row into this table.
  ///
  /// This is equivalent to calling [InsertStatement.insert] - see that method
  /// for more information.
  Future<int> insertOne(
    Insertable<Row> row, {
    InsertMode? mode,
    UpsertClause<Tbl, Row>? onConflict,
  }) {
    return insert().insert(row, mode: mode, onConflict: onConflict);
  }

  /// Atomically inserts all [rows] into the table.
  ///
  /// The [mode] and [onConflict] clause can optionally control the behavior of
  /// an insert if an existing row conflicts with a new one.
  /// Unlike calling [Batch.insertAll] in a [Batch] directly, foreign keys are
  /// checked only _after_ all inserts ran. In other words, the order in which
  /// the [rows] are in doesn't matter if there are foreign keys between them.
  Future<void> insertAll(Iterable<Insertable<Row>> rows,
      {InsertMode? mode, UpsertClause<Tbl, Row>? onConflict}) {
    return attachedDatabase.batch((b) {
      b.customStatement('pragma defer_foreign_keys = on;');
      b.insertAll(this, rows, mode: mode, onConflict: onConflict);
    });
  }

  /// Inserts one row into this table table, replacing an existing row if it
  /// exists already.
  ///
  /// Please note that this method is only available on recent sqlite3 versions.
  /// See also [InsertStatement.insertOnConflictUpdate].
  /// By default, only the primary key is used for detect uniqueness violations.
  /// If you have further uniqueness constraints, please use the general
  /// [insertOne] method with a [DoUpdate] including those columns in its
  /// [DoUpdate.target].
  Future<int> insertOnConflictUpdate(Insertable<Row> row) {
    return insert().insertOnConflictUpdate(row);
  }

  /// Inserts one row into this table and returns it, along with auto-
  /// generated fields.
  ///
  /// Please note that this method is only available on recent sqlite3 versions.
  /// See also [InsertStatement.insertReturning].
  Future<Row> insertReturning(
    Insertable<Row> row, {
    InsertMode? mode,
    UpsertClause<Tbl, Row>? onConflict,
  }) {
    return insert().insertReturning(
      row,
      mode: mode,
      onConflict: onConflict,
    );
  }

  /// Creates a statement to compose an `UPDATE` into the database.
  ///
  /// This is equivalent to calling [DatabaseConnectionUser.update] with the
  /// captured table.
  UpdateStatement<Tbl, Row> update() => attachedDatabase.update(this);

  /// Replaces a single row with an update statement.
  ///
  /// See also [UpdateStatement.replace].
  Future<void> replaceOne(Insertable<Row> row) {
    return update().replace(row);
  }

  /// Creates a statement to compose a `DELETE` from the database.
  ///
  /// This is equivalent to calling [DatabaseConnectionUser.delete] with the
  /// captured table.
  DeleteStatement<Tbl, Row> delete() => attachedDatabase.delete(this);

  /// Deletes the [row] from the captured table.
  Future<bool> deleteOne(Insertable<Row> row) async {
    return await (delete()..whereSamePrimaryKey(row)).go() != 0;
  }

  /// Deletes all rows matching the [filter] from the table.
  ///
  /// See also [SingleTableQueryMixin.where].
  Future<int> deleteWhere(Expression<bool> Function(Tbl tbl) filter) {
    return (delete()..where(filter)).go();
  }

  /// Deletes ALL rows from the table.
  ///
  /// See also [SingleTableQueryMixin.where].
  Future<int> deleteAll() {
    return delete().go();
  }
}
