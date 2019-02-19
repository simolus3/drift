import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/components/limit.dart';
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

    final results = await ctx.database.executor.doWhenOpened((e) async {
      return await ctx.database.executor.runSelect(ctx.sql, ctx.boundVariables);
    });
    return results.map(table.map).toList();
  }

  /// Limits the amount of rows returned by capping them at [limit]. If [offset]
  /// is provided as well, the first [offset] rows will be skipped and not
  /// included in the result.
  void limit(int limit, {int offset}) {
    limitExpr = Limit(limit, offset);
  }

  /// Creates an auto-updating stream that emits new items whenever this table
  /// changes.
  Stream<List<D>> watch() {
    return database.createStream(this);
  }
}
