part of '../analysis.dart';

/// Walks the AST and, for each select statement it sees, finds out which
/// columns are returned and which columns are available. For instance, when
/// we have a table "t" with two columns "a" and "b", the select statement
/// "SELECT a FROM t" has one result column but two columns available.
class ColumnResolver extends RecursiveVisitor<void, void> {
  final AnalysisContext context;

  ColumnResolver(this.context);

  @override
  void visitSelectStatement(SelectStatement e, void arg) {
    // visit children first so that common table expressions are resolved
    visitChildren(e, arg);
    _resolveSelect(e);
  }

  @override
  void visitCompoundSelectStatement(CompoundSelectStatement e, void arg) {
    // first, visit all children so that the compound parts have their columns
    // resolved
    visitChildren(e, arg);

    _resolveCompoundSelect(e);
  }

  @override
  void visitCommonTableExpression(CommonTableExpression e, void arg) {
    visitChildren(e, arg);

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
  void visitDoUpdate(DoUpdate e, void arg) {
    final surroundingInsert = e.parents.whereType<InsertStatement>().first;
    final table = surroundingInsert.table.resultSet;

    if (table != null) {
      // add "excluded" table qualifier that referring to the row that would
      // have been inserted had the uniqueness constraint not been violated.
      e.scope.register('excluded', TableAlias(table, 'excluded'));
    }

    visitChildren(e, arg);
  }

  @override
  void visitUpdateStatement(UpdateStatement e, void arg) {
    final table = _resolveTableReference(e.table);
    e.scope.availableColumns = table.resolvedColumns;
    visitChildren(e, arg);
  }

  @override
  void visitInsertStatement(InsertStatement e, void arg) {
    final table = _resolveTableReference(e.table);
    visitChildren(e, arg);
    e.scope.availableColumns = table.resolvedColumns;
    visitChildren(e, arg);
  }

  @override
  void visitDeleteStatement(DeleteStatement e, void arg) {
    final table = _resolveTableReference(e.from);
    e.scope.availableColumns = table.resolvedColumns;
    visitChildren(e, arg);
  }

  @override
  void visitCreateTriggerStatement(CreateTriggerStatement e, void arg) {
    final table = _resolveTableReference(e.onTable);
    if (table == null) {
      // further analysis is not really possible without knowing the table
      super.visitCreateTriggerStatement(e, arg);
      return;
    }

    final scope = e.scope;
    if (e.target.introducesNew) {
      scope.register('new', TableAlias(table, 'new'));
    }
    if (e.target.introducesOld) {
      scope.register('old', TableAlias(table, 'old'));
    }

    visitChildren(e, arg);
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
        final stmt = select.statement;
        if (stmt is CompoundSelectStatement) {
          _resolveCompoundSelect(stmt);
        } else if (stmt is SelectStatement) {
          _resolveSelect(stmt);
        } else {
          throw AssertionError('Unknown type of select statement: $stmt');
        }

        availableColumns.addAll(stmt.resolvedColumns);
      },
      isJoin: (join) {
        _handle(join.primary, availableColumns);
        for (final query in join.joins.map((j) => j.query)) {
          _handle(query, availableColumns);
        }
      },
      isTableFunction: (function) {
        final handler = context
            .engineOptions.addedTableFunctions[function.name.toLowerCase()];
        final resolved = handler?.resolveTableValued(context, function);

        if (resolved == null) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.unknownFunction,
            message: 'Could not extract the result set for this table function',
            relevantNode: function,
          ));
        } else {
          function.resultSet = resolved;
          availableColumns.addAll(resolved.resolvedColumns);
        }
      },
    );
  }

  void _resolveSelect(SelectStatement s) {
    final availableColumns = <Column>[];
    if (s.from != null) {
      _handle(s.from, availableColumns);
    }

    final usedColumns = <Column>[];
    final scope = s.scope;

    // a select statement can include everything from its sub queries as a
    // result, but also expressions that appear as result columns
    for (final resultColumn in s.columns) {
      if (resultColumn is StarResultColumn) {
        Iterable<Column> visibleColumnsForStar;

        if (resultColumn.tableName != null) {
          final tableResolver = scope
              .resolve<ResolvesToResultSet>(resultColumn.tableName, orElse: () {
            context.reportError(AnalysisError(
              type: AnalysisErrorType.referencedUnknownTable,
              message: 'Unknown table: ${resultColumn.tableName}',
              relevantNode: resultColumn,
            ));
          });

          visibleColumnsForStar = tableResolver.resultSet.resolvedColumns;
        } else {
          // we have a * column without a table, that resolves to every columns
          // available
          visibleColumnsForStar = availableColumns;
        }

        usedColumns
            .addAll(visibleColumnsForStar.where((e) => e.includedInResults));
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
      } else if (resultColumn is NestedStarResultColumn) {
        final target = scope
            .resolve<ResolvesToResultSet>(resultColumn.tableName, orElse: () {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.referencedUnknownTable,
            message: 'Unknown table: ${resultColumn.tableName}',
            relevantNode: resultColumn,
          ));
        });

        if (target != null) resultColumn.resultSet = target.resultSet;
      }
    }

    s.resolvedColumns = usedColumns;
    scope.availableColumns = availableColumns;
  }

  void _resolveCompoundSelect(CompoundSelectStatement statement) {
    final columnSets = [
      statement.base.resolvedColumns,
      for (var part in statement.additional) part.select.resolvedColumns
    ];

    // each select statement must return the same amount of columns
    final amount = columnSets.first.length;
    for (var i = 1; i < columnSets.length; i++) {
      if (columnSets[i].length != amount) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.compoundColumnCountMismatch,
          relevantNode: statement,
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
    statement.resolvedColumns = resolved;
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
      final available = scope.allOf<ResultSet>().map((t) {
        if (t is HumanReadable) {
          return (t as HumanReadable).humanReadableDescription();
        }

        return t.toString();
      });

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
