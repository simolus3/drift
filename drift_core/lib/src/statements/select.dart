import 'package:collection/collection.dart';

import '../builder/context.dart';
import '../schema.dart';
import 'clauses.dart';
import 'statement.dart';

class SelectStatement extends SqlStatement with WhereClause, GeneralFrom {
  final List<SelectColumn> _columns;

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

SelectColumn star() => StarColumn(null, null);

abstract class SelectColumn extends SqlComponent {}

class StarColumn implements SelectColumn {
  final SchemaTable? table;
  final String? tableName;

  StarColumn(this.table, this.tableName);

  @override
  void writeInto(GenerationContext context) {
    if (table != null) {
      final stmt = context.requireScope<StatementScope>();
      final addedTable = stmt.findTable(table!, tableName)!;

      context.buffer
        ..write(
            context.identifier(addedTable.as ?? addedTable.table.schemaName))
        ..write('.');
    }

    context.buffer.write('*');
  }
}
