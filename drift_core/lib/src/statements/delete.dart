import '../builder/context.dart';
import '../schema.dart';
import 'clauses.dart';
import 'statement.dart';

class DeleteStatement extends SqlStatement with WhereClause, SingleFrom {
  @override
  final AddedTable from;

  DeleteStatement(SchemaTable from) : from = AddedTable(from);

  @override
  void writeInto(GenerationContext context) {
    context.pushScope(StatementScope(this));
    context.buffer.write('DELETE FROM ');
    from.writeInto(context);
    writeWhere(context);
    context.buffer.write(';');
    context.popScope();
  }
}
