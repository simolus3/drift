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
    // visit children first so that common table expressions are resolved
    visitChildren(e);
    _resolveSelect(e);
  }

  @override
  void visitCompoundSelectStatement(CompoundSelectStatement e) {
    // first, visit all children so that the compound parts have their columns
    // resolved
    visitChildren(e);

    final columnSets = [
      e.base.resolvedColumns,
      for (var part in e.additional) part.select.resolvedColumns
    ];

    // each select statement must return the same amount of columns
    final amount = columnSets.first.length;
    for (var i = 1; i < columnSets.length; i++) {
      if (columnSets[i].length != amount) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.compoundColumnCountMismatch,
          relevantNode: e,
          message: 'The parts of this compound statement return different '
              'amount of columns',
        ));
        break;
      }
    }

    final resolved = <CompoundSelectColumn>[];

    // merge all columns at each position into a CompoundSelectColumn
    for (var i = 0; i < amount; i++) {
      final columnsAtThisIndex = [
        for (var set in columnSets) if (set.length > i) set[i]
      ];

      resolved.add(CompoundSelectColumn(columnsAtThisIndex));
    }
    e.resolvedColumns = resolved;
  }

  @override
  void visitCommonTableExpression(CommonTableExpression e) {
    visitChildren(e);

    final resolved = e.as.resolvedColumns;
    final names = e.columnNames;
    if (names != null && resolved != null && names.length != resolved.length) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.cteColumnCountMismatch,
        message: 'This CTE declares ${names.length} columns, but its select '
            'statement actually returns ${resolved.length}.',
        relevantNode: e,
      ));
    }
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
        final resolved = _resolveTableReference(table);
        if (resolved != null) {
          // an error will be logged when resolved is null, so the != null check
          // is fine and avoids crashes
          availableColumns.addAll(table.resultSet.resolvedColumns);
        }
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
        final expression = resultColumn.expression;
        Column column;

        if (expression is Reference) {
          column = ReferenceExpressionColumn(expression,
              overriddenName: resultColumn.as);
        } else {
          final name = _nameOfResultColumn(resultColumn);
          column =
              ExpressionColumn(name: name, expression: resultColumn.expression);
        }

        usedColumns.add(column);

        if (resultColumn.as != null) {
          // make this column available for references if there is no other
          // column with the same name
          final name = resultColumn.as;
          if (!availableColumns.any((c) => c.name == name)) {
            availableColumns.add(column);
          }
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

  ResultSet _resolveTableReference(TableReference r) {
    final scope = r.scope;
    final resolvedTable = scope.resolve<ResultSet>(r.tableName, orElse: () {
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
