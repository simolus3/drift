part of '../analysis.dart';

/// Walks the AST and
/// - attaches the global scope containing table names and builtin functions
/// - creates [ReferenceScope] for sub-queries
/// - in each scope, registers every table or subquery that can be referenced to
///   the local [ReferenceScope].
class ReferenceFinder extends RecursiveVisitor<void> {
  final ReferenceScope globalScope;

  ReferenceFinder({@required this.globalScope});

  void start(AstNode root) {
    root
      ..scope = globalScope
      ..accept(this);
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
}
