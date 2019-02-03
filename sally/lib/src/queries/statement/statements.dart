import 'package:meta/meta.dart';
import 'package:sally/src/queries/expressions/expressions.dart';
import 'package:sally/src/queries/expressions/limit.dart';
import 'package:sally/src/queries/expressions/where.dart';
import 'package:sally/src/queries/predicates/predicate.dart';
import 'package:sally/src/queries/table_structure.dart';

/// Mixin for statements that allow a LIMIT operator
class Limitable {

  @protected
  LimitExpression limitExpression;

  void limit({int amount, int offset}) {
    limitExpression = LimitExpression(amount, offset);
  }

  @protected
  bool get hasLimit => limitExpression != null;

}

/// Mixin for statements that allow a WHERE operator on a specific table.
class WhereFilterable<Table, Result> {

  @protected
  TableStructure<Table, Result> table;
  @protected
  WhereExpression whereExpression;

  bool get hasWhere => whereExpression != null;

  void where(Predicate filter(Table table)) {
    final addedPredicate = filter(table.asTable);

    if (hasWhere) {
      // merge existing where expression together with new one by and-ing them
      // together.
      whereExpression = WhereExpression(whereExpression.predicate.and(addedPredicate));
    } else {
      whereExpression = WhereExpression(addedPredicate);
    }
  }

}