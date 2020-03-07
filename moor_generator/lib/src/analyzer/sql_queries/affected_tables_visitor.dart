import 'package:moor/moor.dart' show UpdateKind;
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

  Table /*?*/ _toTableOrNull(ResolvesToResultSet resultSet) {
    var resolved = resultSet.resultSet;

    while (resolved != null && resolved is TableAlias) {
      resolved = (resolved as TableAlias).delegate;
    }

    return resolved is Table ? resolved : null;
  }

  @override
  void visitQueryable(Queryable e, void arg) {
    if (e is TableReference) {
      final resolved = _toTableOrNull(e.resultSet);
      if (resolved != null) {
        foundTables.add(resolved);
      }
    }

    visitChildren(e, arg);
  }
}

class WrittenTable {
  final Table table;
  final UpdateKind kind;

  WrittenTable(this.table, this.kind);
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
  final Set<WrittenTable> writtenTables = {};

  void _addIfResolved(ResolvesToResultSet r, UpdateKind kind) {
    final resolved = _toTableOrNull(r);
    if (resolved != null) {
      writtenTables.add(WrittenTable(resolved, kind));
    }
  }

  @override
  void visitDeleteStatement(DeleteStatement e, void arg) {
    _addIfResolved(e.from, UpdateKind.delete);
    visitChildren(e, arg);
  }

  @override
  void visitUpdateStatement(UpdateStatement e, void arg) {
    _addIfResolved(e.table, UpdateKind.update);
    visitChildren(e, arg);
  }

  @override
  void visitInsertStatement(InsertStatement e, void arg) {
    _addIfResolved(e.table, UpdateKind.insert);
    visitChildren(e, arg);
  }
}
