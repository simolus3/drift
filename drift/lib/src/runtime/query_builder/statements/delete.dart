part of '../query_builder.dart';

/// A `DELETE` statement in sql
class DeleteStatement<T extends Table, D> extends Query<T, D>
    with SingleTableQueryMixin<T, D> {
  /// This constructor should be called by [DatabaseConnectionUser.delete] for
  /// you.
  DeleteStatement(DatabaseConnectionUser database, TableInfo<T, D> table)
      : super(database, table);

  @override
  void writeStartPart(GenerationContext ctx) {
    ctx.buffer.write('DELETE FROM ${table.tableWithAlias}');
  }

  void _prepareDeleteOne(Insertable<D> entity) {
    assert(
        whereExpr == null,
        'When deleting an entity, you may not use where(...)'
        'as well. The where clause will be determined automatically');

    whereSamePrimaryKey(entity);
  }

  /// Deletes just this entity. May not be used together with [where].
  ///
  /// Returns the amount of rows that were deleted by this statement directly
  /// (not including additional rows that might be affected through triggers or
  /// foreign key constraints).
  Future<int> delete(Insertable<D> entity) {
    _prepareDeleteOne(entity);
    return go();
  }

  /// Like [delete], but returns the deleted row from the database.
  ///
  /// If no matching row with the same primary key exists, `null` is returned.
  Future<D?> deleteReturning(Insertable<D> entity) async {
    _prepareDeleteOne(entity);
    writeReturningClause = true;
    return (await _goReturning()).singleOrNull;
  }

  /// Deletes all rows matched by the set [where] clause and the optional
  /// limit.
  ///
  /// Returns the amount of rows that were deleted by this statement directly
  /// (not including additional rows that might be affected through triggers or
  /// foreign key constraints).
  Future<int> go() async {
    final ctx = constructQuery();

    return ctx.executor!.doWhenOpened((e) async {
      final rows = await e.runDelete(ctx.sql, ctx.boundVariables);

      if (rows > 0) {
        database.notifyUpdates(
            {TableUpdate.onTable(_sourceTable, kind: UpdateKind.delete)});
      }
      return rows;
    });
  }

  /// Like [go], but it also returns all rows affected by this delete operation.
  Future<List<D>> goAndReturn() {
    writeReturningClause = true;
    return _goReturning();
  }

  Future<List<D>> _goReturning() async {
    final ctx = constructQuery();

    return ctx.executor!.doWhenOpened((e) async {
      final rows = await e.runSelect(ctx.sql, ctx.boundVariables);

      if (rows.isNotEmpty) {
        database.notifyUpdates(
            {TableUpdate.onTable(_sourceTable, kind: UpdateKind.delete)});
      }

      return rows.mapAsyncAndAwait(table.map);
    });
  }
}
