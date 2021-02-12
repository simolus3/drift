part of '../analysis.dart';

/// Resolves any open [Reference] it finds in the AST.
class ReferenceResolver extends RecursiveVisitor<void, void> {
  final AnalysisContext context;

  ReferenceResolver(this.context);

  @override
  void visitForeignKeyClause(ForeignKeyClause e, void arg) {
    final table = e.foreignTable.resultSet;
    if (table == null) {
      // If the table wasn't found, an earlier step will have reported an error
      return super.visitForeignKeyClause(e, arg);
    }

    for (final columnName in e.columnNames) {
      _resolveReferenceInTable(columnName, table);
    }
  }

  void _resolveReferenceInTable(Reference ref, ResultSet resultSet) {
    final column = resultSet.findColumn(ref.columnName);
    if (column == null) {
      _reportUnknownColumnError(ref, columns: resultSet.resolvedColumns);
    } else {
      ref.resolved = column;
    }
  }

  @override
  void visitReference(Reference e, void arg) {
    if (e.resolved != null) {
      return super.visitReference(e, arg);
    }

    final scope = e.scope;

    if (e.entityName != null) {
      // first find the referenced table or view,
      // then use the column on that table or view.
      final entityResolver = scope.resolve<ResolvesToResultSet>(e.entityName!);
      final resultSet = entityResolver?.resultSet;

      if (resultSet == null) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.referencedUnknownTable,
          message: 'Unknown table or view: ${e.entityName}',
          relevantNode: e,
        ));
      } else {
        _resolveReferenceInTable(e, resultSet);
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
      final columns =
          scope.availableColumns.where((c) => c.name == e.columnName).toSet();

      if (columns.isEmpty) {
        _reportUnknownColumnError(e);
      } else {
        if (columns.length > 1) {
          final description =
              columns.map((c) => c.humanReadableDescription()).join(', ');

          context.reportError(AnalysisError(
            type: AnalysisErrorType.ambiguousReference,
            relevantNode: e,
            message: 'Could refer to any of: $description',
          ));
        }

        e.resolved = columns.first;
      }
    }

    visitChildren(e, arg);
  }

  void _reportUnknownColumnError(Reference e, {Iterable<Column>? columns}) {
    columns ??= e.scope.availableColumns;
    final columnNames = e.scope.availableColumns
        .map((c) => c.humanReadableDescription())
        .join(', ');

    context.reportError(AnalysisError(
      type: AnalysisErrorType.referencedUnknownColumn,
      relevantNode: e,
      message: 'Unknown column. These columns are available: $columnNames',
    ));
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

    final table = from.resolved as Table?;
    if (table == null) return null;

    // table.findColumn contains logic to resolve row id aliases
    return table.findColumn(e.columnName);
  }

  @override
  void visitAggregateExpression(AggregateExpression e, void arg) {
    if (e.windowName != null && e.resolved == null) {
      final resolved = e.scope.resolve<NamedWindowDeclaration>(e.windowName!);
      e.resolved = resolved;
    }

    visitChildren(e, arg);
  }
}
