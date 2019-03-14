import 'package:meta/meta.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/components/limit.dart';
import 'package:moor/src/runtime/components/order_by.dart';
import 'package:moor/src/runtime/components/where.dart';
import 'package:moor/src/runtime/database.dart';
import 'package:moor/src/runtime/expressions/bools.dart';
import 'package:moor/src/runtime/expressions/custom.dart';
import 'package:moor/src/runtime/expressions/expression.dart';
import 'package:moor/src/types/sql_types.dart';
import 'package:moor/src/runtime/structure/table_info.dart';

/// Statement that operates with data that already exists (select, delete,
/// update).
abstract class Query<Table, DataClass> {
  @protected
  QueryEngine database;
  TableInfo<Table, DataClass> table;

  Query(this.database, this.table);

  @protected
  Where whereExpr;
  @protected
  OrderBy orderByExpr;
  @protected
  Limit limitExpr;

  /// Subclasses must override this and write the part of the statement that
  /// comes before the where and limit expression..
  @visibleForOverriding
  void writeStartPart(GenerationContext ctx);

  void where(Expression<bool, BoolType> filter(Table tbl)) {
    final predicate = filter(table.asDslTable);

    if (whereExpr == null) {
      whereExpr = Where(predicate);
    } else {
      whereExpr = Where(and(whereExpr.predicate, predicate));
    }
  }

  /// Constructs the query that can then be sent to the database executor.
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

    if (orderByExpr != null) {
      if (needsWhitespace) ctx.writeWhitespace();

      orderByExpr.writeInto(ctx);
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

  /// Applies a [where] statement so that the row with the same primary key as
  /// [d] will be matched.
  void whereSamePrimaryKey(DataClass d) {
    assert(
        table.$primaryKey != null && table.$primaryKey.isNotEmpty,
        'When using Query.whereSamePrimaryKey, which is also called from '
        'DeleteStatement.delete and UpdateStatement.replace, the affected table'
        'must have a primary key. You can either specify a primary implicitly '
        'by making an integer() column autoIncrement(), or by explictly '
        'overriding the primaryKey getter in your table class. You\'ll also '
        'have to re-run the code generation step.\n'
        'Alternatively, if you\'re using DeleteStatement.delete or '
        'UpdateStatement.replace, consider using DeleteStatement.go or '
        'UpdateStatement.write respectively. In that case, you need to use a '
        'custom where statement.');

    final primaryKeys = table.$primaryKey.map((c) => c.$name);

    final updatedFields = table.entityToSql(d, includeNulls: true);
    // Extract values of the primary key as they are needed for the where clause
    final primaryKeyValues = Map.fromEntries(updatedFields.entries
        .where((entry) => primaryKeys.contains(entry.key)));

    Expression<bool, BoolType> predicate;
    for (var entry in primaryKeyValues.entries) {
      // custom expression that references the column
      final columnExpression = CustomExpression(entry.key);
      final comparison =
          Comparison(columnExpression, ComparisonOperator.equal, entry.value);

      if (predicate == null) {
        predicate = comparison;
      } else {
        predicate = and(predicate, comparison);
      }
    }

    whereExpr = Where(predicate);
  }
}
