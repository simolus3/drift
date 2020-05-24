library utils.find_referenced_tables;

import 'package:sqlparser/sqlparser.dart';

/// An AST-visitor that walks sql statements and finds all tables referenced in
/// them.
class ReferencedTablesVisitor extends RecursiveVisitor<void, void> {
  /// All tables that have been referenced anywhere in this query.
  final Set<Table> foundTables = {};
  final Set<View> foundViews = {};

  void _add(NamedResultSet resultSet) {
    if (resultSet is Table) {
      foundTables.add(resultSet);
    } else if (resultSet is View) {
      foundViews.add(resultSet);
    }
  }

  @override
  void visitReference(Reference e, void arg) {
    final column = e.resolved;
    if (column is TableColumn) {
      _add(column.table);
    } else if (column is ViewColumn) {
      _add(column.view);
    }

    visitChildren(e, arg);
  }

  NamedResultSet /*?*/ _toResultSetOrNull(ResolvesToResultSet resultSet) {
    var resolved = resultSet.resultSet;

    while (resolved != null && resolved is TableAlias) {
      resolved = (resolved as TableAlias).delegate;
    }

    return resolved is NamedResultSet ? resolved : null;
  }

  @override
  void visitQueryable(Queryable e, void arg) {
    if (e is TableReference) {
      final resolved = _toResultSetOrNull(e.resultSet);
      if (resolved != null) {
        _add(resolved);
      }
    }

    visitChildren(e, arg);
  }
}

enum UpdateKind { insert, update, delete }

/// A write to a table as found while analyzing a statement.
class TableWrite {
  /// The table that a statement might write to when run.
  final Table table;

  /// What kind of update was found (e.g. insert, update or delete).
  final UpdateKind kind;

  TableWrite(this.table, this.kind);

  @override
  int get hashCode => 37 * table.hashCode + kind.hashCode;

  @override
  bool operator ==(dynamic other) {
    return other is TableWrite && other.table == table && other.kind == kind;
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
  final Set<TableWrite> writtenTables = {};

  void _addIfResolved(ResolvesToResultSet r, UpdateKind kind) {
    final resolved = _toResultSetOrNull(r);
    if (resolved != null && resolved is Table) {
      writtenTables.add(TableWrite(resolved, kind));
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

/// Finds all writes to a table that occur anywhere inside the [root] node or a
/// descendant.
///
/// The [root] node must have all its references resolved. This means that using
/// a node obtained via [SqlEngine.parse] directly won't report meaningful
/// results. Instead, use [SqlEngine.analyze] or [SqlEngine.analyzeParsed].
///
/// If you want to find all referenced tables, use [findReferencedTables]. If
/// you want to find writes (including their [UpdateKind]) and referenced
/// tables, constrct a [UpdatedTablesVisitor] manually.
/// Then, let it visit the [root] node. You can now use
/// [UpdatedTablesVisitor.writtenTables] and
/// [ReferencedTablesVisitor.foundTables]. This will only walk the ast once,
/// whereas calling this and [findReferencedTables] will require two walks.
///
Set<TableWrite> findWrittenTables(AstNode root) {
  return (UpdatedTablesVisitor()..visit(root, null)).writtenTables;
}

/// Finds all tables referenced in [root] or a descendant.
///
/// The [root] node must have all its references resolved. This means that using
/// a node obtained via [SqlEngine.parse] directly won't report meaningful
/// results. Instead, use [SqlEngine.analyze] or [SqlEngine.analyzeParsed].
///
/// If you want to use both [findWrittenTables] and this on the same ast node,
/// follow the advice on [findWrittenTables] to only walk the ast once.
Set<Table> findReferencedTables(AstNode root) {
  return (ReferencedTablesVisitor()..visit(root, null)).foundTables;
}
