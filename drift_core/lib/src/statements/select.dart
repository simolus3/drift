import 'package:collection/collection.dart';

import '../builder/context.dart';
import '../expressions/expression.dart';
import 'clauses.dart';
import 'statement.dart';

class SelectStatement extends SqlStatement with WhereClause, GeneralFrom {
  final List<Expression> _columns;

  SelectStatement(this._columns);

  @override
  void writeInto(GenerationContext context) {
    context.pushScope(StatementScope(this));
    context.buffer.write('SELECT ');

    _columns.forEachIndexed((index, column) {
      if (index != 0) context.buffer.write(',');

      column.writeInto(context);
    });

    context.writeWhitespace();
    writeFrom(context);
    writeWhere(context);
    context.buffer.write(';');

    context.popScope();
  }
}
