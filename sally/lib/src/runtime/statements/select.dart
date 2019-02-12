import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/executor/executor.dart';
import 'package:sally/src/runtime/statements/query.dart';
import 'package:sally/src/runtime/structure/table_info.dart';

class SelectStatement<T, D> extends Query<T, D> {
  SelectStatement(GeneratedDatabase database, TableInfo<T, D> table)
      : super(database, table);

  @override
  void writeStartPart(GenerationContext ctx) {
    ctx.buffer.write('SELECT * FROM ${table.$tableName}');
  }

  /// Loads and returns all results from this select query.
  Future<List<D>> get() async {
    final ctx = constructQuery();

    final results =
        await ctx.database.executor.runSelect(ctx.sql, ctx.boundVariables);
    return results.map(table.map).toList();
  }
}
