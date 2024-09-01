library utils.find_referenced_tables;

import 'package:sqlparser/sqlparser.dart';

import 'node_to_text.dart';

/// An AST-visitor that walks sql statements and finds all tables referenced in
/// them.
class ReferencedTablesVisitor extends RecursiveVisitor<void, void> {
  /// All tables that have been referenced anywhere in this query.
  final Set<Table> foundTables = {};
  final Set<View> foundViews = {};

  void _add(NamedResultSet? resultSet) {
    if (resultSet is Table) {
      foundTables.add(resultSet);
    } else if (resultSet is View) {
      foundViews.add(resultSet);
    }
  }

  @override
  void visitReference(Reference e, void arg) {
    var column = e.resolved;
    while (column is DelegatedColumn) {
      column = column.innerColumn;
    }

    if (column is TableColumn) {
      _add(column.table);
    } else if (column is ViewColumn) {
      _add(column.view);
    }

    visitChildren(e, arg);
  }

  NamedResultSet? _toResultSetOrNull(ResolvesToResultSet? resultSet) {
    final resolved = resultSet?.resultSet?.unalias();

    return resolved is NamedResultSet ? resolved : null;
  }

  @override
  void visitTableReference(TableReference e, void arg) {
    final resolved = _toResultSetOrNull(e.resultSet);
    if (resolved != null) {
      _add(resolved);
    }

    visitChildren(e, arg);
  }
}

enum UpdateKind { insert, update, delete }

/// A write to a table or view as found while analyzing a statement.
///
/// While views normally can't be written to, sqlite3 supports `INSTEAD OF`
/// triggers allowing other statements to be executed when running writes on
/// views.
class TableWrite {
  /// The table that a statement might write to when run.
  final NamedResultSet table;

  /// What kind of update was found (e.g. insert, update or delete).
  final UpdateKind kind;

  TableWrite(this.table, this.kind);

  @override
  int get hashCode => 37 * table.hashCode + kind.hashCode;

  @override
  bool operator ==(Object other) {
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

  void _addIfResolved(ResolvesToResultSet? r, UpdateKind kind) {
    final resolved = _toResultSetOrNull(r);
    if (resolved != null && (resolved is Table || resolved is View)) {
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

/// Extension to find referenced tables prior to any analysis runs.
extension FindReferenceAnalysis on SqlEngine {
  /// Finds tables references from the global schema before any analyis steps
  /// ran.
  ///
  /// This includes tables added in `FROM` if those tables haven't been added
  /// syntactically, for instance through a `WITH` clause.
  ///
  /// In a sense, this is comparable to finding "free variables" in a syntactic
  /// construct for other languages.
  Set<String> findReferencedSchemaTables(AstNode root) {
    // Poorly clone the AST so that the analysis doesn't bring the original one
    // into a weird state.
    final sql = root.toSql();
    final clone = parse(sql).rootNode;

    final scope = _FakeRootScope();
    final context = AnalysisContext(clone, sql, scope, EngineOptions(),
        schemaSupport: schemaReader);

    AstPreparingVisitor(context: context).start(clone);
    clone.accept(ColumnResolver(context), const ColumnResolverContext());

    return scope.addedTables;
  }
}

class _FakeRootScope extends RootScope {
  final Set<String> addedTables = {};

  @override
  ResultSet? resolveResultSetToAdd(String name) {
    addedTables.add(name.toLowerCase());
    return _FakeResultSet();
  }
}

class _FakeResultSet extends ResultSet {
  @override
  List<Column>? get resolvedColumns => const [];
}
