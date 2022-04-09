import 'package:drift_core/src/builder/context.dart';

import '../expressions/expression.dart';
import '../schema.dart';
import 'clauses.dart';
import 'statement.dart';

abstract class InsertSource extends SqlComponent {
  const InsertSource();
}

class InsertStatement extends SqlStatement with SingleFrom {
  @override
  final TableInQuery from;
  final List<SchemaColumn>? columns;
  final InsertSource source;

  InsertStatement({
    required SchemaTable into,
    required this.source,
    this.columns,
  }) : from = AddedTable(into);

  @override
  void writeInto(GenerationContext context) {
    context.pushScope(StatementScope(this));
    context.buffer.write('INSERT INTO ');
    from.writeInto(context);
    context.buffer.write(' ');

    if (columns != null) {
      context.buffer.write('(');
      var firstColumn = true;
      for (final column in columns!) {
        if (!firstColumn) context.buffer.write(', ');
        firstColumn = false;

        context.buffer.write(context.identifier(column.name));
      }

      context.buffer.write(') ');
    }

    source.writeInto(context);
    context.popScope();
  }
}

class InsertValues extends InsertSource {
  final List<List<Expression>> values;

  InsertValues(this.values);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('VALUES ');

    var firstRow = true;
    for (final row in values) {
      if (!firstRow) context.buffer.write(', ');
      firstRow = false;

      context.buffer.write('(');
      var firstColumn = true;
      for (final column in row) {
        if (!firstColumn) context.buffer.write(',');
        firstColumn = false;

        column.writeInto(context);
      }
      context.buffer.write(')');
    }
  }
}

class DefaultValues extends InsertSource {
  const DefaultValues();

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('DEFAULT VALUES');
  }
}
