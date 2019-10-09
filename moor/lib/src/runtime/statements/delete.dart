import 'dart:async';

import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/statements/query.dart';
import 'package:moor/src/runtime/structure/table_info.dart';

/// A `DELETE` statement in sql
class DeleteStatement<T extends Table, D extends DataClass> extends Query<T, D>
    with SingleTableQueryMixin<T, D> {
  /// This constructor should be called by [QueryEngine.delete] for you.
  DeleteStatement(QueryEngine database, TableInfo<T, D> table)
      : super(database, table);

  @override
  void writeStartPart(GenerationContext ctx) {
    ctx.buffer.write('DELETE FROM ${table.$tableName}');
  }

  /// Deletes just this entity. May not be used together with [where].
  Future<int> delete(Insertable<D> entity) {
    assert(
        whereExpr == null,
        'When deleting an entity, you may not use where(...)'
        'as well. The where clause will be determined automatically');

    whereSamePrimaryKey(entity);
    return go();
  }

  /// Deletes all rows matched by the set [where] clause and the optional
  /// limit.
  Future<int> go() async {
    final ctx = constructQuery();

    return ctx.executor.doWhenOpened((e) async {
      final rows = await ctx.executor.runDelete(ctx.sql, ctx.boundVariables);

      if (rows > 0) {
        database.markTablesUpdated({table});
      }
      return rows;
    });
  }
}
