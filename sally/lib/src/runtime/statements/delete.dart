import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/executor/executor.dart';
import 'package:sally/src/runtime/statements/query.dart';
import 'package:sally/src/runtime/structure/table_info.dart';

class DeleteStatement<UserTable> extends Query<UserTable, dynamic> {
  DeleteStatement(
      GeneratedDatabase database, TableInfo<UserTable, dynamic> table)
      : super(database, table);

  @override
  void writeStartPart(GenerationContext ctx) {
    ctx.buffer.write('DELETE FROM ${table.$tableName}');
  }

  Future<int> go() async {
    final ctx = constructQuery();

    final rows = await ctx.database.executor.runDelete(ctx.sql, ctx.boundVariables);

    if (rows > 0) {
      database.markTableUpdated(table.$tableName);
    }

    return rows;
  }
}
