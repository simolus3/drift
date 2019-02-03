import 'package:sally/src/queries/expressions/expressions.dart';
import 'package:sally/src/queries/statement/statements.dart';
import 'package:sally/src/queries/table_structure.dart';

class DeleteStatement<Table> with Limitable, WhereFilterable<Table, dynamic> {

  DeleteStatement(TableStructure<Table, dynamic> table) {
    super.table = table;
  }

  /// Deletes all records matched by the optional where and limit statements.
  /// Returns the amount of deleted rows.
  Future<int> performDelete() {
    GenerationContext context = GenerationContext();
    context.buffer.write('DELETE FROM ');
    context.buffer.write(table.sqlTableName);
    context.buffer.write(' ');

    if (hasWhere) whereExpression.writeInto(context);
    if (hasLimit) limitExpression.writeInto(context);

    return table.executor.executeDelete(context.buffer.toString(), context.boundVariables);
  }

}