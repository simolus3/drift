import 'package:sqlparser/sqlparser.dart';

/// An AST-visitor that walks sql statements and finds all tables referenced in
/// them.
class ReferencedTablesVisitor extends RecursiveVisitor<void> {
  final Set<Table> foundTables = {};

  @override
  void visitReference(Reference e) {
    final column = e.resolved;
    if (column is TableColumn) {
      foundTables.add(column.table);
    }

    visitChildren(e);
  }

  @override
  void visitQueryable(Queryable e) {
    if (e is TableReference) {
      final resolved = e.resolved;
      if (resolved != null && resolved is Table) {
        foundTables.add(resolved);
      }
    }

    visitChildren(e);
  }
}

/// Finds all tables that could be affected when executing a query. In
/// contrast to [ReferencedTablesVisitor], which finds all references, this
/// visitor only collects tables a query writes to.
class UpdatedTablesVisitor extends RecursiveVisitor<void> {
  final Set<Table> foundTables = {};

  void _addIfResolved(ResolvesToResultSet r) {
    final resolved = r.resultSet;
    if (resolved is Table) {
      foundTables.add(resolved);
    }
  }

  @override
  void visitDeleteStatement(DeleteStatement e) {
    _addIfResolved(e.from);
    visitChildren(e);
  }

  @override
  void visitUpdateStatement(UpdateStatement e) {
    _addIfResolved(e.table);
    visitChildren(e);
  }

  @override
  void visitInsertStatement(InsertStatement e) {
    _addIfResolved(e.table);
    visitChildren(e);
  }
}
