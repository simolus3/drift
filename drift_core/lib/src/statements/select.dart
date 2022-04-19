import 'package:collection/collection.dart';

import '../builder/context.dart';
import '../schema.dart';
import 'clauses.dart';
import 'insert.dart';
import 'statement.dart';

class SelectStatement extends SqlStatement
    with WhereClause, GeneralFrom
    implements InsertSource {
  final List<SelectColumn> _columns;
  bool _distinct;

  SelectStatement(this._columns, {bool distinct = false})
      : _distinct = distinct;

  void distinct() => _distinct = true;

  @override
  void writeInto(GenerationContext context) {
    context.pushScope(StatementScope(this));
    context.buffer.write('SELECT ');
    if (_distinct) {
      context.buffer.write('DISTINCT ');
    }

    _columns.forEachIndexed((index, column) {
      if (index != 0) context.buffer.write(',');

      column.writeInto(context);
    });

    context.writeWhitespace();
    writeFrom(context);
    writeWhere(context);
    context.popScope();

    // If this select statement isn't part of another statement, write a
    // semicolon
    if (context.scope<StatementScope>() == null) {
      context.buffer.write(';');
    }
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
