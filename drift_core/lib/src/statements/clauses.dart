@internal
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../builder/context.dart';
import '../expressions/boolean.dart';
import '../expressions/expression.dart';
import '../schema.dart';
import 'statement.dart';

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

  @protected
  void writeWhere(GenerationContext context) {
    final clause = whereClause;
    if (clause != null) {
      context.buffer.write(' WHERE ');
      clause.writeInto(context);
    }
  }
}

mixin SingleFrom on SqlStatement {
  @visibleForOverriding
  TableInQuery get from;

  @override
  List<TableInQuery> get primaryTables => [from];

  @protected
  void writeFrom(GenerationContext context) {
    context.buffer.write('FROM ');
    from.writeInto(context);
  }
}

mixin GeneralFrom on SqlStatement {
  @override
  final List<TableInQuery> primaryTables = [];

  void from(EntityWithResult table, [String? as]) {
    primaryTables.add(AddedTable(table, as));
  }

  void innerJoin(
    EntityWithResult table, {
    String? as,
    Expression<bool>? on,
  }) {
    primaryTables
        .add(JoinedTable(JoinOperator.innerJoin, AddedTable(table, as), on));
  }

  void leftJoin(
    EntityWithResult table, {
    String? as,
    Expression<bool>? on,
  }) {
    primaryTables
        .add(JoinedTable(JoinOperator.outerJoin, AddedTable(table, as), on));
  }

  void crossJoin(EntityWithResult table, [String? as]) {
    primaryTables
        .add(JoinedTable(JoinOperator.crossJoin, AddedTable(table, as)));
  }

  @internal
  void writeFrom(GenerationContext context) {
    context.buffer.write('FROM ');
    primaryTables.forEachIndexed((index, table) {
      if (index != 0) context.writeWhitespace();

      table.writeInto(context);
    });
  }
}

abstract class TableInQuery implements SqlComponent {}

class AddedTable extends TableInQuery {
  final EntityWithResult table;
  final String? as;

  AddedTable(this.table, [this.as]);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write(context.identifier(table.name));

    if (as != null) {
      context.buffer
        ..write(' AS ')
        ..write(context.identifier(as!));
    }
  }
}

enum JoinOperator {
  innerJoin,
  outerJoin,
  crossJoin,
}

class JoinedTable extends TableInQuery {
  final JoinOperator operator;
  final AddedTable table;
  final Expression<bool>? constraint;

  JoinedTable(this.operator, this.table, [this.constraint]);

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

    if (constraint != null) {
      context.buffer.write(' ON ');
      constraint!.writeInto(context);
    }
  }
}
