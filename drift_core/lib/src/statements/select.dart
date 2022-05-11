import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../builder/context.dart';
import '../expressions/expression.dart';
import '../schema.dart';
import 'clauses.dart';
import 'insert.dart';
import 'statement.dart';

class SelectStatement extends SqlStatement
    with WhereClause, GeneralFrom
    implements InsertSource {
  final List<SelectColumn> _columns;

  int? _limitCount, _limitOffset;

  bool _distinct;

  SelectStatement(this._columns, {bool distinct = false})
      : _distinct = distinct;

  void distinct() => _distinct = true;

  void limit(int count, {int? offset}) {
    _limitCount = count;
    _limitOffset = offset;
  }

  @override
  SelectStatementScope writeInto(GenerationContext context) {
    final scope = SelectStatementScope(this);
    context.pushScope(scope);
    context.buffer.write('SELECT ');
    if (_distinct) {
      context.buffer.write('DISTINCT ');
    }

    _columns.forEachIndexed((index, column) {
      if (index != 0) context.buffer.write(',');

      if (column is Expression) {
        final name = scope._writeColumn(column);

        column.writeInto(context);
        context.buffer
          ..write(' ')
          ..write(name);
      } else {
        assert(column is StarColumn, 'Unknown select column type $column');
        column.writeInto(context);
      }
    });

    context.writeWhitespace();
    writeFrom(context);
    writeWhere(context);

    if (_limitCount != null) {
      context.buffer.write(' LIMIT $_limitCount');
      if (_limitOffset != null) {
        context.buffer.write(' OFFSET $_limitOffset');
      }
    }

    context.popScope();

    // If this select statement isn't part of another statement, write a
    // semicolon
    if (context.scope<StatementScope>() == null) {
      context.buffer.write(';');
    }
    return scope;
  }
}

class SelectStatementScope extends StatementScope {
  final Map<Expression, String> _columnAliases = {};

  SelectStatementScope(SelectStatement statement) : super(statement);

  String _writeColumn(Expression expression) {
    return _columnAliases.putIfAbsent(expression, () {
      return 'c${_columnAliases.length}';
    });
  }

  String columnName(Expression expression) {
    return _columnAliases[expression]!;
  }

  String columnNameInTable(SchemaColumn column, {String? tableAlias}) {
    return columnName(column(tableAlias));
  }
}

SelectColumn star() => StarColumn(null, null);

@sealed
abstract class SelectColumn extends SqlComponent {}

class StarColumn implements SelectColumn {
  final SchemaTable? table;
  final String? tableName;

  StarColumn(this.table, this.tableName);

  @override
  void writeInto(GenerationContext context) {
    if (table != null) {
      final scope = context.requireScope<SelectStatementScope>();

      var first = true;
      for (final column in table!.columns) {
        if (!first) {
          context.buffer.write(', ');
        }

        final expr = column(tableName);
        expr.writeInto(context);

        final alias = scope._writeColumn(expr);
        context.buffer
          ..write(' ')
          ..write(alias);

        first = false;
      }
    } else {
      // todo: This needs to be desured into a column list as well
      context.buffer.write('*');
    }
  }
}
