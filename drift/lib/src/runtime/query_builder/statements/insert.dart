part of '../query_builder.dart';

/// Represents an insert statement
class InsertStatement<T extends Table, D> {
  /// The database to use then executing this statement
  @protected
  final DatabaseConnectionUser database;

  /// The table we're inserting into
  @protected
  final TableInfo<T, D> table;

  /// Constructs an insert statement from the database and the table. Used
  /// internally by drift.
  InsertStatement(this.database, this.table);

  /// Inserts a row into the table and returns it.
  ///
  /// Depending on the [InsertMode] or the [DoUpdate] `onConflict` clause, the
  /// insert statement may not actually insert a row into the database. Since
  /// this function was declared to return a non-nullable row, it throws an
  /// exception in that case. Use [insertReturningOrNull] when performing an
  /// insert with an insert mode like [InsertMode.insertOrIgnore] or when using
  /// a [DoUpdate] with a `where` clause clause.
  Future<D> insertReturning(Insertable<D> entity,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) async {
    final row =
        await insertReturningOrNull(entity, mode: mode, onConflict: onConflict);

    if (row == null) {
      throw StateError('The insert statement did not insert any rows that '
          'could be returned. Please use insertReturningOrNull() when using a '
          '`DoUpdate` clause with `where`.');
    }

    return row;
  }

  /// Inserts a row into the table and returns it.
  ///
  /// When no row was inserted and no exception was thrown, for instance because
  /// [InsertMode.insertOrIgnore] was used or because the upsert clause had a
  /// `where` clause that didn't match, `null` is returned instead.
  Future<D?> insertReturningOrNull(Insertable<D> entity,
      {InsertMode? mode, UpsertClause<T, D>? onConflict}) async {
    final ctx = createContext(entity, mode ?? InsertMode.insert,
        onConflict: onConflict, returning: true);

    return database.withCurrentExecutor((e) async {
      final result = await e.runSelect(ctx.sql, ctx.boundVariables);
      if (result.isNotEmpty) {
        database.notifyUpdates(
            {TableUpdate.onTable(table, kind: UpdateKind.insert)});
        return table.map(result.single);
      } else {
        return null;
      }
    });
  }

  /// Attempts to [insert] [entity] into the database. If the insert would
  /// violate a primary key or uniqueness constraint, updates the columns that
  /// are present on [entity].
  ///
  /// Note that this is subtly different from [InsertMode.replace]! When using
  /// [InsertMode.replace], the old row will be deleted and replaced with the
  /// new row. With [insertOnConflictUpdate], columns from the old row that are
  /// not present on [entity] are unchanged, and no row will be deleted.
  ///
  /// Be aware that [insertOnConflictUpdate] uses an upsert clause, which is not
  /// available on older sqlite implementations.
  /// Note: By default, only the primary key is used for detect uniqueness
  /// violations. If you have further uniqueness constraints, please use the
  /// general [insert] method with a [DoUpdate] including those columns in its
  /// [DoUpdate.target].
  Future<int> insertOnConflictUpdate(Insertable<D> entity) {
    return insert(entity, onConflict: DoUpdate((_) => entity));
  }
}

/// Enumeration of different insert behaviors. See the documentation on the
/// individual fields for details.
enum InsertMode implements Component {
  /// A regular `INSERT INTO` statement. When a row with the same primary or
  /// unique key already exists, the insert statement will fail and an exception
  /// will be thrown. If the exception is caught, previous statements made in
  /// the same transaction will NOT be reverted.
  insert,

  /// Identical to [InsertMode.insertOrReplace], included for the sake of
  /// completeness.
  replace,

  /// Like [insert], but if a row with the same primary or unique key already
  /// exists, it will be deleted and re-created with the row being inserted.
  insertOrReplace,

  /// Similar to [InsertMode.insertOrAbort], but it will revert the surrounding
  /// transaction if a constraint is violated, even if the thrown exception is
  /// caught.
  insertOrRollback,

  /// Identical to [insert], included for the sake of completeness.
  insertOrAbort,

  /// Like [insert], but if multiple values are inserted with the same insert
  /// statement and one of them fails, the others will still be completed.
  insertOrFail,

  /// Like [insert], but failures will be ignored.
  insertOrIgnore;

  @override
  void writeInto(GenerationContext ctx) {
    if (ctx.dialect == SqlDialect.postgres &&
        this != InsertMode.insert &&
        this != InsertMode.insertOrIgnore) {
      throw ArgumentError('$this not supported on postgres');
    }

    ctx.buffer.write(_insertKeywords[
        ctx.dialect == SqlDialect.postgres ? InsertMode.insert : this]);
  }
}

const _insertKeywords = <InsertMode, String>{
  InsertMode.insert: 'INSERT',
  InsertMode.replace: 'REPLACE',
  InsertMode.insertOrReplace: 'INSERT OR REPLACE',
  InsertMode.insertOrRollback: 'INSERT OR ROLLBACK',
  InsertMode.insertOrAbort: 'INSERT OR ABORT',
  InsertMode.insertOrFail: 'INSERT OR FAIL',
  InsertMode.insertOrIgnore: 'INSERT OR IGNORE',
};
