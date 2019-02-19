import 'package:sally/sally.dart';
import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/components/limit.dart';
import 'package:sally/src/runtime/executor/executor.dart';
import 'package:sally/src/runtime/statements/query.dart';
import 'package:sally/src/runtime/structure/table_info.dart';

typedef OrderingTerm OrderClauseGenerator<T>(T tbl);

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

  /// Orders the result by the given clauses. The clauses coming first in the
  /// list have a higher priority, the later clauses are only considered if the
  /// first clause considers two rows to be equal.
  void orderBy(List<OrderClauseGenerator<T>> clauses) {
    orderByExpr = OrderBy(clauses.map((t) => t(table.asDslTable)).toList());
  }

  /// Creates an auto-updating stream that emits new items whenever this table
  /// changes.
  Stream<List<D>> watch() {
    return database.createStream(this);
  }
}
