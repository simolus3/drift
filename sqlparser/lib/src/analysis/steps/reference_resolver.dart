part of '../analysis.dart';

/// Resolves any open [Reference] it finds in the AST.
class ReferenceResolver
    extends RecursiveVisitor<ReferenceResolvingContext, void> {
  final AnalysisContext context;

  ReferenceResolver(this.context);

  @override
  void visitInsertStatement(InsertStatement e, ReferenceResolvingContext arg) {
    final table = e.table.resultSet;
    if (table != null) {
      // Resolve columns in the main table
      for (final column in e.targetColumns) {
        _resolveReferenceInTable(column, table);
      }
    }

    visitChildren(e, arg);
  }

  @override
  void visitGroupBy(GroupBy e, ReferenceResolvingContext arg) {
    return super.visitGroupBy(
        e, const ReferenceResolvingContext(canReferToColumnAlias: true));
  }

  @override
  void visitOrderBy(OrderBy e, ReferenceResolvingContext arg) {
    return super.visitOrderBy(
        e, ReferenceResolvingContext(canReferToColumnAlias: true));
  }

  @override
  void visitReference(Reference e, ReferenceResolvingContext arg) {
    if (e.resolved != null) {
      return super.visitReference(e, arg);
    }

    final scope = e.scope;

    if (e.entityName != null) {
      // first find the referenced table or view,
      // then use the column on that table or view.
      final entityResolver = scope.resolveResultSetForReference(e.entityName!);
      final resultSet = entityResolver?.resultSet.resultSet;

      if (resultSet == null) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.referencedUnknownTable,
          message: 'Unknown table or view: ${e.entityName}',
          relevantNode: e,
        ));
      } else {
        _resolveReferenceInTable(e, resultSet, source: entityResolver);
      }
    } else if (aliasesForRowId.contains(e.columnName.toLowerCase())) {
      // special case for aliases to a rowid
      final column = _resolveRowIdAlias(e);

      if (column == null) {
        _reportUnknownColumnError(e);
      } else {
        e.resolved = column;
      }
    } else {
      // find any column with the referenced name.
      // todo special case for USING (...) in joins?
      final found = scope.resolveUnqualifiedReference(
        e.columnName,
        allowReferenceToResultColumn: arg.canReferToColumnAlias,
      );

      if (found.isEmpty) {
        _reportUnknownColumnError(e);
      } else {
        if (found.length > 1) {
          final description =
              found.map((c) => c.humanReadableDescription()).join(', ');

          context.reportError(AnalysisError(
            type: AnalysisErrorType.ambiguousReference,
            relevantNode: e,
            message: 'Could refer to any of: $description',
          ));
        }

        e.resolved = found.first;
      }
    }

    visitChildren(e, arg);
  }

  @override
  void visitUpdateStatement(UpdateStatement e, ReferenceResolvingContext arg) {
    final table = e.table.resultSet;
    if (table != null) {
      // Resolve the set components against the primary table
      for (final set in e.set) {
        for (final column in set.columns) {
          _resolveReferenceInTable(column, table);
        }
      }
    }

    visitChildren(e, arg);
  }

  @override
  void visitWindowFunctionInvocation(
      WindowFunctionInvocation e, ReferenceResolvingContext arg) {
    if (e.windowName != null && e.resolved == null) {
      e.resolved =
          StatementScope.cast(e.scope).windowDeclarations[e.windowName!];
    }

    visitChildren(e, arg);
  }

  void _reportUnknownColumnError(Reference e, {Iterable<Column>? columns}) {
    final msg = StringBuffer('Unknown column.');
    if (columns != null) {
      final columnNames =
          columns.map((c) => c.humanReadableDescription()).join(', ');
      msg.write(' These columns are available: $columnNames');
    }

    context.reportError(AnalysisError(
      type: AnalysisErrorType.referencedUnknownColumn,
      relevantNode: e,
      message: msg.toString(),
    ));
  }

  void _resolveReferenceInTable(Reference ref, ResultSet resultSet,
      {ResultSetAvailableInStatement? source}) {
    var column = resultSet.findColumn(ref.columnName);
    if (column == null) {
      _reportUnknownColumnError(ref, columns: resultSet.resolvedColumns);
    } else {
      if (source != null) {
        column = AvailableColumn(column, source);
      }
      ref.resolved = column;
      ref.resultEntity = source;
    }
  }

  Column? _resolveRowIdAlias(Reference e) {
    // to resolve those aliases when they're not bound to a table, the
    // surrounding statement may only read from one table
    final stmt = e.enclosingOfType<HasPrimarySource>();

    if (stmt == null) return null;

    final from = stmt.table;
    if (from is! TableReference) {
      return null;
    }

    final resolved = from.resultSet?.unalias();
    if (resolved is! Table) return null;

    // table.findColumn contains logic to resolve row id aliases
    return resolved.findColumn(e.columnName);
  }
}

class ReferenceResolvingContext {
  /// Whether unqualified references can be resolved against a column alias from
  /// the surrounding select statement.
  ///
  /// This is only the case for `ORDER BY`, `GROUP BY` and `HAVING` clauses.
  final bool canReferToColumnAlias;

  const ReferenceResolvingContext({
    this.canReferToColumnAlias = false,
  });
}
