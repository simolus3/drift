part of '../analysis.dart';

/// Walks the AST and
/// - attaches the global scope containing table names and builtin functions
/// - creates [ReferenceScope] for sub-queries
/// - in each scope, registers everything that can be referenced to the local
///   [ReferenceScope].
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
    // we need to fork the scope here.
    final scope = e.scope;
    final forked = scope.createChild();
    e.scope = forked;
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
        // the same goes for select statements
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
