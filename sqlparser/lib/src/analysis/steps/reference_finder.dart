part of '../analysis.dart';

/// Walks the AST and
/// - attaches the global scope containing table names and builtin functions
/// - creates [ReferenceScope] for sub-queries
/// - in each scope, registers every table or subquery that can be referenced to
///   the local [ReferenceScope].
/// - determines the [Variable.resolvedIndex] for each [Variable] in this
///   statement.
class ReferenceFinder extends RecursiveVisitor<void> {
  final ReferenceScope globalScope;
  final List<Variable> _foundVariables = [];

  ReferenceFinder({@required this.globalScope});

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
      final forked = scope.effectiveRoot.createChild();
      e.scope = forked;
    } else {
      final forked = scope.createChild();
      e.scope = forked;
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
}
