import 'package:meta/meta.dart';
import 'package:sally/src/runtime/components/component.dart';
import 'package:sally/src/runtime/components/limit.dart';
import 'package:sally/src/runtime/components/where.dart';
import 'package:sally/src/runtime/executor/executor.dart';
import 'package:sally/src/runtime/expressions/bools.dart';
import 'package:sally/src/runtime/expressions/expression.dart';
import 'package:sally/src/runtime/sql_types.dart';
import 'package:sally/src/runtime/structure/table_info.dart';

/// Statement that operates with data that already exists (select, delete,
/// update).
abstract class Query<Table, DataClass> {
  @protected
  GeneratedDatabase database;
  TableInfo<Table, DataClass> table;

  Query(this.database, this.table);

  @protected
  Where whereExpr;
  @protected
  Limit limitExpr;

  void writeStartPart(GenerationContext ctx);

  void where(Expression<BoolType> filter(Table tbl)) {
    final predicate = filter(table.asDslTable);

    if (whereExpr == null) {
      whereExpr = Where(predicate);
    } else {
      whereExpr = Where(and(whereExpr.predicate, predicate));
    }
  }

  void limit(int limit, {int offset}) {
    limitExpr = Limit(limit, offset);
  }

  @protected
  GenerationContext constructQuery() {
    final ctx = GenerationContext(database);
    var needsWhitespace = false;

    writeStartPart(ctx);
    needsWhitespace = true;

    if (whereExpr != null) {
      if (needsWhitespace) ctx.writeWhitespace();

      whereExpr.writeInto(ctx);
      needsWhitespace = true;
    }

    if (limitExpr != null) {
      if (needsWhitespace) ctx.writeWhitespace();

      limitExpr.writeInto(ctx);
      needsWhitespace = true;
    }

    ctx.buffer.write(';');

    return ctx;
  }
}
