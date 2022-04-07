import '../builder/context.dart';
import '../expressions/expression.dart';
import '../schema.dart';
import 'clauses.dart';
import 'statement.dart';

class UpdateStatement extends SqlStatement with WhereClause, SingleFrom {
  @override
  final AddedTable from;

  final Map<SchemaColumn, Expression> _updates;

  UpdateStatement(SchemaTable from, this._updates) : from = AddedTable(from);

  @override
  void writeInto(GenerationContext context) {
    context.pushScope(StatementScope(this));
    context.buffer.write('UPDATE ');
    from.writeInto(context);

    context.buffer.write(' SET ');
    var i = 0;
    _updates.forEach((column, expr) {
      if (i != 0) {
        context.buffer.write(', ');
      }

      context.buffer
        ..write(context.identifier(column.name))
        ..write(' = ');
      expr.writeInto(context);
      i++;
    });

    writeWhere(context);
    context.buffer.write(';');
    context.popScope();
  }
}
