part of '../analysis.dart';

/// Walks the AST and, for each select statement it sees, finds out which
/// columns are returned and which columns are available. For instance, when
/// we have a table "t" with two columns "a" and "b", the select statement
/// "SELECT a FROM t" has one result column but two columns available.
class ColumnResolver extends RecursiveVisitor<void> {
  final AnalysisContext context;

  ColumnResolver(this.context);

  @override
  void visitSelectStatement(SelectStatement e) {
    _resolveSelect(e);
    visitChildren(e);
  }

  @override
  void visitUpdateStatement(UpdateStatement e) {
    final table = _resolveTableReference(e.table);
    e.scope.availableColumns = table.resolvedColumns;
    visitChildren(e);
  }

  @override
  void visitInsertStatement(InsertStatement e) {
    final table = _resolveTableReference(e.table);
    visitChildren(e);
    e.scope.availableColumns = table.resolvedColumns;
    visitChildren(e);
  }

  @override
  void visitDeleteStatement(DeleteStatement e) {
    final table = _resolveTableReference(e.from);
    e.scope.availableColumns = table.resolvedColumns;
    visitChildren(e);
  }

  void _handle(Queryable queryable, List<Column> availableColumns) {
    queryable.when(
      isTable: (table) {
        _resolveTableReference(table);
        availableColumns.addAll(table.resultSet.resolvedColumns);
      },
      isSelect: (select) {
        // the inner select statement doesn't have access to columns defined in
        // the outer statements, which is why we use _resolveSelect instead of
        // passing availableColumns down to a recursive call of _handle
        _resolveSelect(select.statement);
        availableColumns.addAll(select.statement.resolvedColumns);
      },
      isJoin: (join) {
        _handle(join.primary, availableColumns);
        for (var query in join.joins.map((j) => j.query)) {
          _handle(query, availableColumns);
        }
      },
    );
  }

  void _resolveSelect(SelectStatement s) {
    final availableColumns = <Column>[];
    for (var queryable in s.from) {
      _handle(queryable, availableColumns);
    }

    final usedColumns = <Column>[];
    final scope = s.scope;

    // a select statement can include everything from its sub queries as a
    // result, but also expressions that appear as result columns
    for (var resultColumn in s.columns) {
      if (resultColumn is StarResultColumn) {
        if (resultColumn.tableName != null) {
          final tableResolver = scope
              .resolve<ResolvesToResultSet>(resultColumn.tableName, orElse: () {
            context.reportError(AnalysisError(
              type: AnalysisErrorType.referencedUnknownTable,
              message: 'Unknown table: ${resultColumn.tableName}',
              relevantNode: resultColumn,
            ));
          });

          usedColumns.addAll(tableResolver.resultSet.resolvedColumns);
        } else {
          // we have a * column, that would be all available columns
          usedColumns.addAll(availableColumns);
        }
      } else if (resultColumn is ExpressionResultColumn) {
        final name = _nameOfResultColumn(resultColumn);
        final column =
            ExpressionColumn(name: name, expression: resultColumn.expression);

        usedColumns.add(column);

        // make this column available if there is no other with the same name
        if (!availableColumns.any((c) => c.name == name)) {
          availableColumns.add(column);
        }
      }
    }

    s.resolvedColumns = usedColumns;
    scope.availableColumns = availableColumns;
  }

  String _nameOfResultColumn(ExpressionResultColumn c) {
    if (c.as != null) return c.as;

    if (c.expression is Reference) {
      return (c.expression as Reference).columnName;
    }

    // in this case it's just the literal expression. So for instance,
    // "SELECT 3+  5" has a result column called "3+ 5" (consecutive whitespace
    // is removed).
    final span = context.sql.substring(c.firstPosition, c.lastPosition);
    // todo remove consecutive whitespace
    return span;
  }

  Table _resolveTableReference(TableReference r) {
    final scope = r.scope;
    final resolvedTable = scope.resolve<Table>(r.tableName, orElse: () {
      final available = scope.allOf<Table>().map((t) => t.name);

      context.reportError(UnresolvedReferenceError(
        type: AnalysisErrorType.referencedUnknownTable,
        relevantNode: r,
        reference: r.tableName,
        available: available,
      ));
    });
    return r.resolved = resolvedTable;
  }
}
