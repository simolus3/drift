part of '../analysis.dart';

/// Walks the AST and, for each select statement it sees, finds out which
/// columns are returned and which columns are available. For instance, when
/// we have a table "t" with two columns "a" and "b", the select statement
/// "SELECT a FROM t" has one result column but two columns available.
class ColumnResolver extends RecursiveVisitor<ColumnResolverContext, void> {
  final AnalysisContext context;

  ColumnResolver(this.context);

  @override
  void visitSelectStatement(SelectStatement e, ColumnResolverContext arg) {
    e.withClause?.accept(this, arg);
    _resolveSelect(e, arg);

    // We've handled the from clause in _resolveSelect, but we still need to
    // visit other children to handle things like subquery expressions.
    for (final child in e.childNodes) {
      if (child != e.withClause && child != e.from) {
        visit(child, arg);
      }
    }
  }

  @override
  void visitCreateIndexStatement(
      CreateIndexStatement e, ColumnResolverContext arg) {
    _handle(e.on, [], arg);
    visitExcept(e, e.on, arg);
  }

  @override
  void visitCreateTriggerStatement(
      CreateTriggerStatement e, ColumnResolverContext arg) {
    final table = _resolveTableReference(e.onTable, arg);
    if (table == null) {
      // further analysis is not really possible without knowing the table
      super.visitCreateTriggerStatement(e, arg);
      return;
    }

    final scope = e.statementScope;

    // Add columns of the target table for when and update of clauses
    scope.expansionOfStarColumn = table.resolvedColumns;

    if (e.target.introducesNew) {
      scope.addAlias(e, table, 'new');
    }
    if (e.target.introducesOld) {
      scope.addAlias(e, table, 'old');
    }

    visitChildren(e, arg);
  }

  @override
  void visitCompoundSelectStatement(
      CompoundSelectStatement e, ColumnResolverContext arg) {
    e.withClause?.accept(this, arg);
    e.base.accept(this, arg);
    visitList(e.additional, arg);

    _resolveCompoundSelect(e);
  }

  @override
  void visitValuesSelectStatement(
      ValuesSelectStatement e, ColumnResolverContext arg) {
    e.withClause?.accept(this, arg);
    _resolveValuesSelect(e);

    // Still visit expressions because they could have subqueries that we need
    // to handle.
    visitList(e.values, arg);
  }

  @override
  void visitCommonTableExpression(
      CommonTableExpression e, ColumnResolverContext arg) {
    // If we have a compound select statement as a CTE, resolve the initial
    // query first because the whole CTE will have those columns in the end.
    // This allows subsequent parts of the compound select to refer to the CTE.
    final query = e.as;
    final contextForFirstChild = ColumnResolverContext(
      referencesUseNameOfReferencedColumn: false,
      inDefinitionOfCte: [
        ...arg.inDefinitionOfCte,
        e.cteTableName.toLowerCase(),
      ],
    );

    void applyColumns(BaseSelectStatement source) {
      final resolved = source.resolvedColumns!;
      final names = e.columnNames;

      if (names == null) {
        e.resolvedColumns = resolved;
      } else {
        if (names.length != resolved.length) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.cteColumnCountMismatch,
            message:
                'This CTE declares ${names.length} columns, but its select '
                'statement actually returns ${resolved.length}.',
            relevantNode: e.tableNameToken ?? e,
          ));
        }

        final cteColumns = names
            .map((name) => CommonTableExpressionColumn(name)..containingSet = e)
            .toList();
        for (var i = 0; i < cteColumns.length; i++) {
          if (i < resolved.length) {
            final selectColumn = resolved[i];
            cteColumns[i].innerColumn = selectColumn;
          }
        }
        e.resolvedColumns = cteColumns;
      }
    }

    if (query is CompoundSelectStatement) {
      // The first nested select statement determines the columns of this CTE.
      query.base.accept(this, contextForFirstChild);
      applyColumns(query.base);

      // Subsequent queries can refer to the CTE though.
      final contextForOtherChildren = ColumnResolverContext(
        referencesUseNameOfReferencedColumn: false,
        inDefinitionOfCte: arg.inDefinitionOfCte,
      );

      visitList(query.additional, contextForOtherChildren);
      _resolveCompoundSelect(query);
    } else {
      visitChildren(e, contextForFirstChild);
      applyColumns(query);
    }
  }

  @override
  void visitDoUpdate(DoUpdate e, ColumnResolverContext arg) {
    final surroundingInsert = e.parents.whereType<InsertStatement>().first;
    final table = surroundingInsert.table.resultSet;

    if (table != null) {
      // add "excluded" table qualifier that referring to the row that would
      // have been inserted had the uniqueness constraint not been violated.
      e.scope.addAlias(e, table, 'excluded');
    }

    visitChildren(e, arg);
  }

  @override
  void visitForeignKeyClause(ForeignKeyClause e, ColumnResolverContext arg) {
    _resolveTableReference(e.foreignTable, arg);
    visitExcept(e, e.foreignTable, arg);
  }

  @override
  void visitUpdateStatement(UpdateStatement e, ColumnResolverContext arg) {
    // Resolve CTEs first
    e.withClause?.accept(this, arg);

    final availableColumns = <Column>[];

    // Add columns from the main table, if it was resolved
    _handle(e.table, availableColumns, arg);
    // Also add columns from a FROM clause, if one is present
    final from = e.from;
    if (from != null) _handle(from, availableColumns, arg);

    e.statementScope.expansionOfStarColumn = availableColumns;
    for (final child in e.childNodes) {
      // Visit remaining children
      if (child != e.table && child != e.from && child != e.withClause) {
        visit(child, arg);
      }
    }

    _resolveReturningClause(e, e.table.resultSet, arg);
  }

  ResultSet? _addIfResolved(
      AstNode node, TableReference ref, ColumnResolverContext arg) {
    final availableColumns = <Column>[];
    _handle(ref, availableColumns, arg);

    final scope = node.statementScope;
    scope.expansionOfStarColumn = availableColumns;

    return ref.resultSet;
  }

  @override
  void visitInsertStatement(InsertStatement e, ColumnResolverContext arg) {
    // Resolve CTEs first
    e.withClause?.accept(this, arg);

    _handle(e.table, [], arg);
    for (final child in e.childNodes) {
      if (child != e.withClause) visit(child, arg);
    }
    _resolveReturningClause(e, e.table.resultSet, arg);
  }

  @override
  void visitDeleteStatement(DeleteStatement e, ColumnResolverContext arg) {
    // Resolve CTEs first
    e.withClause?.accept(this, arg);

    final from = _addIfResolved(e, e.from, arg);
    for (final child in e.childNodes) {
      if (child != e.withClause) visit(child, arg);
    }
    _resolveReturningClause(e, from, arg);
  }

  /// Infers the result set of a `RETURNING` clause.
  ///
  /// The behavior of `RETURNING` clauses is a bit weird when there are multiple
  /// tables available (which can happen with `UPDATE FROM`). When a star column
  /// is used, it only expands to columns from the main table:
  /// ```sql
  /// CREATE TABLE x (a, b);
  /// -- here, the `*` in returning does not include columns from `old`.
  /// UPDATE x SET a = x.a + 1 FROM (SELECT * FROM x) AS old RETURNING *;
  /// ```
  ///
  /// However, individual columns from other tables are available and supported:
  /// ```sql
  /// UPDATE x SET a = x.a + 1 FROM (SELECT * FROM x) AS old
  ///   RETURNING old.a, old.b;
  /// ```
  ///
  /// Note that `old.*` is forbidden by sqlite and not applicable here.
  void _resolveReturningClause(
    StatementReturningColumns stmt,
    ResultSet? mainTable,
    ColumnResolverContext context,
  ) {
    final clause = stmt.returning;
    if (clause == null) return;

    final columns = _resolveColumns(
      stmt.statementScope,
      clause.columns,
      context,
      columnsForStar: mainTable?.resolvedColumns,
    );
    stmt.returnedResultSet = CustomResultSet(columns);
  }

  /// Visits a [queryable] appearing in a `FROM` clause under the state [state].
  ///
  /// This also adds columns contributed to the resolved source to
  /// [availableColumns], which is later used to expand `*` parameters.
  void _handle(Queryable queryable, List<Column> availableColumns,
      ColumnResolverContext state) {
    void addColumns(Iterable<Column> columns) {
      ResultSetAvailableInStatement? available;
      if (queryable is TableOrSubquery) {
        available = queryable.availableResultSet;
      }

      if (available != null) {
        availableColumns.addAll(
            [for (final column in columns) AvailableColumn(column, available)]);
      } else {
        availableColumns.addAll(columns);
      }
    }

    final scope = queryable.scope;

    void markAvailableResultSet(
        Queryable source, ResolvesToResultSet resultSet, String? name) {
      final added = ResultSetAvailableInStatement(source, resultSet);

      if (source is TableOrSubquery) {
        source.availableResultSet = added;
      }

      scope.addResolvedResultSet(name, added);
    }

    queryable.when(
      isTable: (table) {
        final resolved = _resolveTableReference(table, state);
        markAvailableResultSet(
            table, resolved ?? table, table.as ?? table.tableName);

        if (resolved != null) {
          addColumns(table.resultSet!.resolvedColumns!);
        }
      },
      isSelect: (select) {
        markAvailableResultSet(select, select.statement, select.as);

        // Inside subqueries, references don't take the name of the referenced
        // column.
        final childState = ColumnResolverContext(
          referencesUseNameOfReferencedColumn: false,
          inDefinitionOfCte: state.inDefinitionOfCte,
        );
        final stmt = select.statement;

        visit(stmt, childState);
        addColumns(stmt.resolvedColumns!);
      },
      isJoin: (joinClause) {
        _handle(joinClause.primary, availableColumns, state);
        for (final join in joinClause.joins) {
          _handle(join.query, availableColumns, state);

          final constraint = join.constraint;
          if (constraint is OnConstraint) {
            visit(constraint.expression, state);
          }
        }
      },
      isTableFunction: (function) {
        final handler = context
            .engineOptions.addedTableFunctions[function.name.toLowerCase()];
        final resolved = handler?.resolveTableValued(context, function);

        markAvailableResultSet(
            function, resolved ?? function, function.as ?? function.name);

        if (resolved == null) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.unknownFunction,
            message: 'Could not extract the result set for this table function',
            relevantNode: function,
          ));
        } else {
          function.resultSet = resolved;
          addColumns(resolved.resolvedColumns!);
        }
      },
    );
  }

  void _resolveSelect(SelectStatement s, ColumnResolverContext context) {
    final availableColumns = <Column>[];
    if (s.from != null) {
      _handle(s.from!, availableColumns, context);
    }

    final scope = s.statementScope;
    scope.expansionOfStarColumn = availableColumns;

    s.resolvedColumns = _resolveColumns(scope, s.columns, context);
  }

  List<Column> _resolveColumns(StatementScope scope, List<ResultColumn> columns,
      ColumnResolverContext state,
      {List<Column>? columnsForStar}) {
    final usedColumns = <Column>[];
    final availableColumns = <Column>[...?scope.expansionOfStarColumn];

    // a select statement can include everything from its sub queries as a
    // result, but also expressions that appear as result columns
    for (final resultColumn in columns) {
      if (resultColumn is StarResultColumn) {
        Iterable<Column>? visibleColumnsForStar;

        if (resultColumn.tableName != null) {
          final tableResolver =
              scope.resolveResultSetForReference(resultColumn.tableName!);
          if (tableResolver == null) {
            context.reportError(AnalysisError(
              type: AnalysisErrorType.referencedUnknownTable,
              message: 'Unknown table: ${resultColumn.tableName}',
              relevantNode: resultColumn,
            ));
            continue;
          }

          visibleColumnsForStar =
              tableResolver.resultSet.resultSet?.resolvedColumns?.map(
                  (tableColumn) => AvailableColumn(tableColumn, tableResolver));
        } else {
          // we have a * column without a table, that resolves to every column
          // available
          visibleColumnsForStar =
              columnsForStar ?? scope.expansionOfStarColumn ?? const [];

          // Star columns can't be used without a table (e.g. `SELECT *` is
          // not allowed)
          if (scope.resultSets.isEmpty) {
            context.reportError(AnalysisError(
              type: AnalysisErrorType.starColumnWithoutTable,
              message: "Can't use * when no tables have been added",
              relevantNode: resultColumn,
            ));
          }
        }

        final added =
            visibleColumnsForStar!.where((e) => e.includedInResults).toList();

        usedColumns.addAll(added);
        resultColumn.resolvedColumns = added;
      } else if (resultColumn is ExpressionResultColumn) {
        final expression = resultColumn.expression;
        Column column;

        if (expression is Reference) {
          var fixedName = resultColumn.as;
          if (!state.referencesUseNameOfReferencedColumn) {
            fixedName = _nameOfResultColumn(resultColumn);
          }

          column = ReferenceExpressionColumn(
            expression,
            overriddenName: fixedName,
            mappedBy: resultColumn.mappedBy,
          );
        } else {
          final name = _nameOfResultColumn(resultColumn)!;
          column = ExpressionColumn(
            name: name,
            expression: resultColumn.expression,
            mappedBy: resultColumn.mappedBy,
          );
        }

        usedColumns.add(column);
        resultColumn.resolvedColumns = [column];

        if (resultColumn.as != null) {
          // make this column available for references if there is no other
          // column with the same name
          final name = resultColumn.as;
          if (!availableColumns.any((c) => c.name == name)) {
            availableColumns.add(column);
            scope.namedResultColumns.add(column);
          }
        }
      } else if (resultColumn is NestedStarResultColumn) {
        final target =
            scope.resolveResultSetForReference(resultColumn.tableName);

        if (target == null) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.referencedUnknownTable,
            message: 'Unknown table: ${resultColumn.tableName}',
            relevantNode: resultColumn,
          ));
          continue;
        }

        resultColumn.resultSet = target.resultSet.resultSet;
      } else if (resultColumn is NestedQueryColumn) {
        _resolveSelect(resultColumn.select, state);
      }
    }

    return usedColumns;
  }

  void _resolveCompoundSelect(CompoundSelectStatement statement) {
    final columnSets = [
      statement.base.resolvedColumns,
      for (var part in statement.additional) part.select.resolvedColumns
    ];

    // each select statement must return the same amount of columns
    final amount = columnSets.first!.length;
    for (var i = 1; i < columnSets.length; i++) {
      if (columnSets[i]!.length != amount) {
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
        for (var set in columnSets)
          if (set!.length > i) set[i]
      ];

      resolved.add(
          CompoundSelectColumn(columnsAtThisIndex)..containingSet = statement);
    }
    statement.resolvedColumns = resolved;
  }

  void _resolveValuesSelect(ValuesSelectStatement statement) {
    // ideally all tuples should have the same arity, but the parser doesn't
    // enforce that.
    final amountOfColumns =
        statement.values.fold<int?>(null, (maxLength, tuple) {
      final lengthHere = tuple.expressions.length;
      return maxLength == null ? lengthHere : max(maxLength, lengthHere);
    })!;

    final columns = <Column>[];

    for (var i = 0; i < amountOfColumns; i++) {
      // Columns in a VALUES clause appear to be named "Column$i", where i is a
      // one-based index.
      final columnName = 'Column${i + 1}';
      final expressions = statement.values
          .where((tuple) => tuple.expressions.length > i)
          .map((tuple) => tuple.expressions[i])
          .toList();

      columns.add(ValuesSelectColumn(columnName, expressions)
        ..containingSet = statement);
    }

    statement.resolvedColumns = columns;
  }

  String? _nameOfResultColumn(ExpressionResultColumn c) {
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

  ResultSet? _resolveTableReference(
      TableReference r, ColumnResolverContext state) {
    // Check for circular references
    if (state.inDefinitionOfCte.contains(r.tableName.toLowerCase())) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.circularReference,
        relevantNode: r,
        message: 'Circular reference to its own CTE',
      ));
      return null;
    }

    final scope = r.scope;

    // Try resolving to a top-level table in the schema and to a result set that
    // may have been added to the table
    final resolvedInSchema = scope.resolveResultSetToAdd(r.tableName);
    final createdName = r.as;

    if (resolvedInSchema != null) {
      return r.resolved = createdName != null
          ? TableAlias(resolvedInSchema, createdName)
          : resolvedInSchema;
    } else {
      Iterable<String>? available;

      if (scope is StatementScope) {
        available = StatementScope.cast(scope)
            .allAvailableResultSets
            .where((e) => e.resultSet.resultSet != null)
            .map((t) {
          final resultSet = t.resultSet.resultSet;
          if (resultSet is HumanReadable) {
            return (resultSet as HumanReadable).humanReadableDescription();
          }

          return t.toString();
        });
      }

      context.reportError(UnresolvedReferenceError(
        type: AnalysisErrorType.referencedUnknownTable,
        relevantNode: r,
        reference: r.tableName,
        available: available ?? const Iterable.empty(),
      ));
    }

    return null;
  }
}

class ColumnResolverContext {
  /// Whether reference columns should use the name of the referenced column as
  /// their own name (as opposed to their lexeme).
  ///
  /// This typically doesn't make a difference, as references uses the same
  /// name as the referenced column. It does make a difference for rowid
  /// references though:
  ///
  /// ```sql
  /// CREATE TABLE foo (id INTEGER NOT NULL PRIMARY KEY);
  ///
  /// SELECT rowid FROM foo; -- returns a column named "id"
  /// SELECT * FROM (SELECT rowid FROM foo); -- returns a column named "rowid"
  /// WITH bar AS (SELECT rowid FROM foo) SELECT * FROM bar; -- again, "rowid"
  /// ```
  ///
  /// As the example shows, references don't take the name of their referenced
  /// column in subqueries or CTEs.
  final bool referencesUseNameOfReferencedColumn;

  /// The common table expressions that are currently being defined.
  ///
  /// This is used to detect forbidden circular references.
  final List<String> inDefinitionOfCte;

  const ColumnResolverContext({
    this.referencesUseNameOfReferencedColumn = true,
    this.inDefinitionOfCte = const [],
  });
}
