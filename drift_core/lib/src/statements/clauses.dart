@internal
import 'package:meta/meta.dart';

import '../builder/context.dart';
import '../expressions/boolean.dart';
import '../expressions/expression.dart';
import '../schema.dart';

@internal
mixin WhereClause {
  @internal
  Expression<bool>? whereClause;

  void where(Expression<bool> where) {
    if (whereClause != null) {
      whereClause = whereClause! & where;
    } else {
      whereClause = where;
    }
  }
}

mixin GeneralFrom {
  final List<TableInQuery> tables = [];

  void from(EntityWithResult table, [String? as]) {
    tables.add(AddedTable(table, as));
  }

  @internal
  void writeFrom(GenerationContext context) {
    context.buffer.write('FROM ');
    for (final table in tables) {
      table.writeInto(context);
    }
  }
}

abstract class TableInQuery implements SqlComponent {}

class AddedTable extends TableInQuery {
  final EntityWithResult table;
  final String? as;

  AddedTable(this.table, this.as);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write(table.name);

    if (as != null) {
      context.buffer
        ..write(' AS ')
        ..write(as);
    }
  }
}

enum JoinOperator {
  innerJoin,
  outerJoin,
  crossJoin,
}

class Join extends TableInQuery {
  final JoinOperator operator;
  final AddedTable table;

  Join(this.operator, this.table);

  @override
  void writeInto(GenerationContext context) {
    switch (operator) {
      case JoinOperator.innerJoin:
        context.buffer.write('INNER JOIN ');
        break;
      case JoinOperator.outerJoin:
        context.buffer.write('OUTER JOIN ');
        break;
      case JoinOperator.crossJoin:
        context.buffer.write('CROSS JOIN ');
        break;
    }

    table.writeInto(context);
  }
}
