import 'package:sqlparser/sqlparser.dart';

/// An AST-visitor that walks sql statements and finds all tables referenced in
/// them.
class ReferencedTablesVisitor extends RecursiveVisitor<void, void> {
  /// All tables that have been referenced anywhere in this query.
  final Set<Table> foundTables = {};

  @override
  void visitReference(Reference e, void arg) {
    final column = e.resolved;
    if (column is TableColumn) {
      foundTables.add(column.table);
    }

    visitChildren(e, arg);
  }

  @override
  void visitQueryable(Queryable e, void arg) {
    if (e is TableReference) {
      final resolved = e.resolved;
      if (resolved != null && resolved is Table) {
        foundTables.add(resolved);
      }
    }

    visitChildren(e, arg);
  }
}

/// Finds all tables that could be affected when executing a query. In
/// contrast to [ReferencedTablesVisitor], which finds all references, this
/// visitor only collects tables a query writes to.
class UpdatedTablesVisitor extends ReferencedTablesVisitor {
  /// All tables that can potentially be updated by this query.
  ///
  /// Note that this is a subset of [foundTables], since an updating tables
  /// could reference tables it's not updating (e.g. with `INSERT INTO foo
  /// SELECT * FROM bar`).
  final Set<Table> writtenTables = {};

  void _addIfResolved(ResolvesToResultSet r) {
    final resolved = r.resultSet;
    if (resolved is Table) {
      writtenTables.add(resolved);
    }
  }

  @override
  void visitDeleteStatement(DeleteStatement e, void arg) {
    _addIfResolved(e.from);
    visitChildren(e, arg);
  }

  @override
  void visitUpdateStatement(UpdateStatement e, void arg) {
    _addIfResolved(e.table);
    visitChildren(e, arg);
  }

  @override
  void visitInsertStatement(InsertStatement e, void arg) {
    _addIfResolved(e.table);
    visitChildren(e, arg);
  }
}
