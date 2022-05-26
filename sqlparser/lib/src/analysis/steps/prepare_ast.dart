part of '../analysis.dart';

/// Prepares the AST for further analysis. This visitor
/// - creates [ReferenceScope]s for sub-queries
/// - in each scope, registers every table or subquery that can be referenced to
///   the local [ReferenceScope].
/// - determines the [Variable.resolvedIndex] for each [Variable] in this
///   statement.
/// - reports syntactic errors that aren't handled in the parser to keep that
///   implementation simpler.
class AstPreparingVisitor extends RecursiveVisitor<void, void> {
  final List<Variable> _foundVariables = [];
  final AnalysisContext context;

  AstPreparingVisitor({required this.context});

  void start(AstNode root) {
    root.accept(this, null);
    resolveIndexOfVariables(_foundVariables);
  }

  @override
  void visitCreateTableStatement(CreateTableStatement e, void arg) {
    final scope = e.scope = StatementScope.forStatement(context.rootScope, e);
    final knownTable = context.rootScope.knownTables[e.tableName];

    // This is used so that tables can refer to their own columns. Code using
    // tables would first register the table and then run analysis again.
    if (knownTable is Table) {
      scope
        ..expansionOfStarColumn = knownTable.resolvedColumns
        ..resultSets[null] = ResultSetAvailableInStatement(e, knownTable);
    }

    visitChildren(e, arg);
  }

  @override
  void visitCreateViewStatement(CreateViewStatement e, void arg) {
    e.scope = StatementScope.forStatement(context.rootScope, e);
    visitChildren(e, arg);
  }

  @override
  void visitSelectStatement(SelectStatement e, void arg) {
    // a select statement can appear as a sub query which has its own scope, so
    // we need to fork the scope here. There is one special case though:
    // Select statements that appear as a query source can't depend on data
    // defined in the outer scope. This is different from select statements
    // that work as expressions.
    // For instance, if you go to sqliteonline.com and issue the following
    // query: "SELECT * FROM demo d1,
    //   (SELECT * FROM demo i WHERE i.id = d1.id) d2;"
    // it won't work.
    final isInFROM = e.parent is Queryable;
    StatementScope scope;

    if (isInFROM) {
      final surroundingSelect = e.parents
          .firstWhere((node) => node is HasFrom)
          .scope as StatementScope;
      scope = StatementScope(SubqueryInFromScope(surroundingSelect));
    } else {
      scope = StatementScope.forStatement(context.rootScope, e);
    }

    e.scope = scope;

    for (final windowDecl in e.windowDeclarations) {
      scope.windowDeclarations[windowDecl.name] = windowDecl;
    }

    // only the last statement in a compound select statement may have an order
    // by or a limit clause
    if (e.parent is CompoundSelectPart || e.parent is CompoundSelectStatement) {
      bool isLast;
      if (e.parent is CompoundSelectPart) {
        final part = e.parent as CompoundSelectPart;
        final compoundSelect = part.parent as CompoundSelectStatement;

        final index = compoundSelect.additional.indexOf(part);
        isLast = index == compoundSelect.additional.length - 1;
      } else {
        // if the parent is the compound select statement, this select query is
        // the [CompoundSelectStatement.base], so definitely not the last query.
        isLast = false;
      }

      if (!isLast) {
        if (e.limit != null) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.synctactic,
            message: 'Limit clause must appear in the last compound statement',
            relevantNode: e.limit,
          ));
        }
        if (e.orderBy != null) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.synctactic,
            message: 'Order by clause must appear in the compound statement',
            relevantNode: e.orderBy,
          ));
        }
      }
    }

    visitChildren(e, arg);
  }

  @override
  void defaultQueryable(Queryable e, void arg) {
    final scope = e.scope;

    e.when(
      isTable: (table) {
        final added = ResultSetAvailableInStatement(table, table);
        table.availableResultSet = added;

        scope.addResolvedResultSet(table.as ?? table.tableName, added);
      },
      isSelect: (select) {
        final added = ResultSetAvailableInStatement(select, select.statement);
        select.availableResultSet = added;
        scope.addResolvedResultSet(select.as, added);
      },
      isJoin: (join) {
        // the join can contain multiple tables. Luckily for us, all of them are
        // Queryables, so we can deal with them by visiting the children and
        // dont't need to do anything here.
      },
      isTableFunction: (function) {
        final added = ResultSetAvailableInStatement(function, function);
        function.availableResultSet = added;
        scope.addResolvedResultSet(function.as ?? function.name, added);
      },
    );

    visitChildren(e, arg);
  }

  @override
  void visitCommonTableExpression(CommonTableExpression e, void arg) {
    StatementScope.cast(e.scope).additionalKnownTables[e.cteTableName] = e;
    visitChildren(e, arg);
  }

  @override
  void visitForeignKeyClause(ForeignKeyClause e, void arg) {
    e.scope = SingleTableReferenceScope(e.scope);
    visitChildren(e, arg);
  }

  @override
  void visitNumberedVariable(NumberedVariable e, void arg) {
    _foundVariables.add(e);
    visitChildren(e, arg);
  }

  @override
  void visitNamedVariable(ColonNamedVariable e, void arg) {
    _foundVariables.add(e);
    visitChildren(e, arg);
  }

  static void resolveIndexOfVariables(List<Variable> variables) {
    // sort variables by the order in which they appear inside the statement.
    variables.sort((a, b) {
      return a.firstPosition.compareTo(b.firstPosition);
    });
    // Assigning rules are explained at https://www.sqlite.org/lang_expr.html#varparam
    var largestAssigned = 0;
    final resolvedNames = <String, int>{};

    for (final variable in variables) {
      if (variable is NumberedVariable) {
        // if the variable has an explicit index (e.g ?123), then 123 is the
        // resolved index and the next variable will have index 124. Otherwise,
        // just assigned the current largest assigned index plus one.
        if (variable.explicitIndex != null) {
          final index = variable.resolvedIndex = variable.explicitIndex!;
          largestAssigned = max(largestAssigned, index);
        } else {
          variable.resolvedIndex = largestAssigned + 1;
          largestAssigned++;
        }
      } else if (variable is ColonNamedVariable) {
        // named variables behave just like numbered vars without an explicit
        // index, but of course two variables with the same name must have the
        // same index.
        final index = resolvedNames.putIfAbsent(variable.name, () {
          return ++largestAssigned;
        });
        variable.resolvedIndex = index;
      }
    }
  }

  @override
  void defaultNode(AstNode e, void arg) {
    // hack to fork scopes on statements (selects are handled above)
    if (e is Statement && e is! SelectStatement) {
      e.scope = StatementScope.forStatement(context.rootScope, e);
    }

    visitChildren(e, arg);
  }

  @override
  void visitUpsertClause(UpsertClause e, void arg) {
    for (var i = 0; i < e.entries.length; i++) {
      _visitUpsertClauseEntry(e.entries[i], i == e.entries.length - 1);
    }
  }

  void _visitUpsertClauseEntry(UpsertClauseEntry e, bool isLast) {
    // Every DoUpdate except for the last ON CONFLICT clause must have a
    // conflict target. When using older sqlite versions, every clause needs
    // a conflict target.
    final lastWithoutTargetOk =
        context.engineOptions.version >= SqliteVersion.v3_35;
    final withoutTargetOk = lastWithoutTargetOk && isLast;
    if (e.onColumns == null && e.action is DoUpdate && !withoutTargetOk) {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.synctactic,
        message: 'Expected a conflict clause when using DO UPDATE',
        relevantNode: e.action,
      ));
    }

    // DO UPDATE clauses have their own reference scope, in which the row
    // "excluded" can be referred. Setting that row happens in the column
    // resolver
    if (e.action is DoUpdate) {
      e.action.scope = MiscStatementSubScope(e.scope as StatementScope);
    }

    visitChildren(e, null);
  }

  /// If a nested query was found. Collect everything separately.
  @override
  void visitDriftSpecificNode(DriftSpecificNode e, void arg) {
    if (e is NestedQueryColumn) {
      // create a new scope for the nested query to differentiate between
      // references that can be resolved in the nested query and references
      // which require data from the parent query
      e.select.scope = MiscStatementSubScope(e.scope as StatementScope);
      AstPreparingVisitor(context: context).start(e.select);
    } else {
      super.visitDriftSpecificNode(e, arg);
    }
  }
}
