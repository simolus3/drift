part of '../analysis.dart';

/// Resolves any open [Reference] it finds in the AST.
class ReferenceResolver extends RecursiveVisitor<void> {
  final AnalysisContext context;

  ReferenceResolver(this.context);

  @override
  void visitReference(Reference e) {
    if (e.resolved != null) {
      return super.visitReference(e);
    }

    final scope = e.scope;

    if (e.tableName != null) {
      // first find the referenced table, then use the column on that table.
      final tableResolver = scope.resolve<ResolvesToResultSet>(e.tableName);
      final resultSet = tableResolver?.resultSet;

      if (resultSet == null) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.referencedUnknownTable,
          message: 'Unknown table: ${e.tableName}',
          relevantNode: e,
        ));
      } else {
        final column = resultSet.findColumn(e.columnName);
        if (column == null) {
          _reportUnknownColumnError(e, columns: resultSet.resolvedColumns);
        } else {
          e.resolved = column;
        }
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
          scope.availableColumns.where((c) => c?.name == e.columnName).toSet();

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

    visitChildren(e);
  }

  void _reportUnknownColumnError(Reference e, {Iterable<Column> columns}) {
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

  Column _resolveRowIdAlias(Reference e) {
    // to resolve those aliases when they're not bound to a table, the
    // surrounding select statement may only read from one table
    final select = e.parents.firstWhere((node) => node is SelectStatement,
        orElse: () => null) as SelectStatement;

    if (select == null) return null;
    if (select.from.length != 1 || select.from.single is! TableReference) {
      return null;
    }

    final table = (select.from.single as TableReference).resolved as Table;
    if (table == null) return null;

    // table.findColumn contains logic to resolve row id aliases
    return table.findColumn(e.columnName);
  }

  @override
  void visitAggregateExpression(AggregateExpression e) {
    if (e.windowName != null && e.resolved == null) {
      final resolved = e.scope.resolve<NamedWindowDeclaration>(e.windowName);
      e.resolved = resolved;
    }

    visitChildren(e);
  }
}
