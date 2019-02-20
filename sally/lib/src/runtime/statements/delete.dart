import 'dart:async';

import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/executor/executor.dart';
import 'package:sally/src/runtime/statements/query.dart';
import 'package:sally/src/runtime/structure/table_info.dart';

class DeleteStatement<UserTable> extends Query<UserTable, dynamic> {
  /// This constructor should be called by [GeneratedDatabase.delete] for you.
  DeleteStatement(
      GeneratedDatabase database, TableInfo<UserTable, dynamic> table)
      : super(database, table);

  @override
  void writeStartPart(GenerationContext ctx) {
    ctx.buffer.write('DELETE FROM ${table.$tableName}');
  }

  /// Deletes all rows matched by the set [where] clause and the optional
  /// limit.
  Future<int> go() async {
    final ctx = constructQuery();

    return ctx.database.executor.doWhenOpened((e) async {
      final rows =
          await ctx.database.executor.runDelete(ctx.sql, ctx.boundVariables);

      if (rows > 0) {
        database.markTableUpdated(table.$tableName);
      }
      return rows;
    });
  }
}
