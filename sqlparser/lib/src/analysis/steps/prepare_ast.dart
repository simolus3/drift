part of '../analysis.dart';

/// Prepares the AST for further analysis. This visitor:
/// - attaches the global scope containing table names and builtin functions
/// - creates [ReferenceScope]s for sub-queries
/// - in each scope, registers every table or subquery that can be referenced to
///   the local [ReferenceScope].
/// - determines the [Variable.resolvedIndex] for each [Variable] in this
///   statement.
/// - reports syntactic errors that aren't handled in the parser to keep that
///   implementation simpler.
class AstPreparingVisitor extends RecursiveVisitor<void> {
  final ReferenceScope globalScope;
  final List<Variable> _foundVariables = [];
  final AnalysisContext context;

  AstPreparingVisitor({@required this.globalScope, this.context});

  void start(AstNode root) {
    root
      ..scope = globalScope
      ..accept(this);

    _resolveIndexOfVariables();
  }

  @override
  void visitSelectStatement(SelectStatement e) {
    // a select statement can appear as a sub query which has its own scope, so
    // we need to fork the scope here. There is one special case though:
    // Select statements that appear as a query source can't depend on data
    // defined in the outer scope. This is different from select statements
    // that work as expressions.
    // For instance, if you go to sqliteonline.com and issue the following
    // query: "SELECT * FROM demo d1, (SELECT * FROM demo i WHERE i.id = d1.id) d2;"
    // it won't work.
    final isInFROM = e.parent is Queryable;
    final scope = e.scope;

    if (isInFROM) {
      final surroundingSelect =
          e.parents.firstWhere((node) => node is BaseSelectStatement).scope;
      final forked = surroundingSelect.createSibling();
      e.scope = forked;
    } else {
      final forked = scope.createChild();
      e.scope = forked;
    }

    for (var windowDecl in e.windowDeclarations) {
      e.scope.register(windowDecl.name, windowDecl);
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

    visitChildren(e);
  }

  @override
  void visitResultColumn(ResultColumn e) {
    if (e is StarResultColumn) {
      // doesn't need special treatment, star expressions can't be referenced
    } else if (e is ExpressionResultColumn) {
      if (e.as != null) {
        e.scope.register(e.as, e);
      }
    }
    visitChildren(e);
  }

  @override
  void visitQueryable(Queryable e) {
    final scope = e.scope;
    e.when(
      isTable: (table) {
        // we're looking at something like FROM table (AS alias). The alias
        // acts like a table for expressions in the same scope, so let's
        // register it.
        if (table.as != null) {
          scope.register(table.as, table);
        }
      },
      isSelect: (select) {
        if (select.as != null) {
          scope.register(select.as, select.statement);
        }
      },
      isJoin: (join) {
        // the join can contain multiple tables. Luckily for us, all of them are
        // Queryables, so we can deal with them by visiting the children and
        // dont't need to do anything here.
      },
    );

    visitChildren(e);
  }

  @override
  void visitCommonTableExpression(CommonTableExpression e) {
    e.scope.register(e.cteTableName, e);
    visitChildren(e);
  }

  @override
  void visitNumberedVariable(NumberedVariable e) {
    _foundVariables.add(e);
    visitChildren(e);
  }

  @override
  void visitNamedVariable(ColonNamedVariable e) {
    _foundVariables.add(e);
    visitChildren(e);
  }

  void _resolveIndexOfVariables() {
    // sort variables by the order in which they appear inside the statement.
    _foundVariables.sort((a, b) {
      return a.firstPosition.compareTo(b.firstPosition);
    });
    // Assigning rules are explained at https://www.sqlite.org/lang_expr.html#varparam
    var largestAssigned = 0;
    final resolvedNames = <String, int>{};

    for (var variable in _foundVariables) {
      if (variable is NumberedVariable) {
        // if the variable has an explicit index (e.g ?123), then 123 is the
        // resolved index and the next variable will have index 124. Otherwise,
        // just assigned the current largest assigned index plus one.
        if (variable.explicitIndex != null) {
          variable.resolvedIndex = variable.explicitIndex;
          largestAssigned = max(largestAssigned, variable.resolvedIndex);
        } else {
          variable.resolvedIndex = largestAssigned + 1;
          largestAssigned++;
        }
      } else if (variable is ColonNamedVariable) {
        // named variables behave just like numbered vars without an explicit
        // index, but of course two variables with the same name must have the
        // same index.
        final index = resolvedNames.putIfAbsent(variable.name, () {
          largestAssigned++;
          return largestAssigned;
        });
        variable.resolvedIndex = index;
      }
    }
  }

  void _forkScope(AstNode node) {
    node.scope = node.scope.createChild();
  }

  @override
  void visitChildren(AstNode e) {
    // hack to fork scopes on statements (selects are handled above)
    if (e is Statement && e is! SelectStatement) {
      _forkScope(e);
    }

    super.visitChildren(e);
  }
}
