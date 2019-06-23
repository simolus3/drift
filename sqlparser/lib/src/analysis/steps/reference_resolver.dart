part of '../analysis.dart';

class ReferenceResolver extends RecursiveVisitor<void> {
  final AnalysisContext context;

  ReferenceResolver(this.context);

  @override
  void visitFunction(FunctionExpression e) {
    final scope = e.scope;
    e.resolved = scope.resolve<SqlFunction>(e.name, orElse: () {
      context.reportError(AnalysisError(
        type: AnalysisErrorType.unknownFunction,
        relevantNode: e,
        message: 'Unknown function: ${e.name}',
      ));
    });
    visitChildren(e);
  }

  @override
  void visitReference(Reference e) {
    final scope = e.scope;

    if (e.tableName != null) {
      // first find the referenced table, then use the column on that table.
      final tableResolver =
          scope.resolve<ResolvesToResultSet>(e.tableName, orElse: () {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.referencedUnknownTable,
          message: 'Unknown table: ${e.tableName}',
          relevantNode: e,
        ));
      });
      final resultSet = _resolve(tableResolver, scope);

      if (resultSet == null) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.referencedUnknownTable,
          relevantNode: e,
        ));
      } else {
        final column = resultSet.findColumn(e.columnName);
        if (column == null) {
          context.reportError(AnalysisError(
            type: AnalysisErrorType.referencedUnknownColumn,
            relevantNode: e,
          ));
        } else {
          e.resolved = column;
        }
      }
    } else {
      // find any column with the referenced name.
      // todo special case for USING (...) in joins?
      final tables = scope.allOf<ResolvesToResultSet>();
      final columns = tables
          .map((t) => _resolve(t, scope)?.findColumn(e.columnName))
          .where((c) => c != null)
          .toSet();

      if (columns.isEmpty) {
        context.reportError(AnalysisError(
            type: AnalysisErrorType.referencedUnknownColumn, relevantNode: e));
      } else {
        if (columns.length > 1) {
          context.reportError(AnalysisError(
              type: AnalysisErrorType.ambiguousReference, relevantNode: e));
        }

        e.resolved = columns.first;
      }
    }

    visitChildren(e);
  }

  ResultSet _resolve(ResolvesToResultSet resolver, ReferenceScope scope,
      {Function orElse()}) {
    // already resolved? don't do the same work twice!
    if (resolver.resultSet != null) {
      return resolver.resultSet;
    }

    if (resolver is ResultSet) {
      return resolver;
    } else if (resolver is TableReference) {
      final table = resolver;
      final resolvedTable = scope.resolve<Table>(table.tableName, orElse: () {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.referencedUnknownTable,
          relevantNode: table,
          message: 'The table ${table.tableName} could not be found',
        ));
      });
      table.resolved = resolvedTable;
      return resolvedTable;
    }

    throw ArgumentError('Resolving not yet implemented for $resolver');
  }

  @override
  void visitQueryable(Queryable e) {
    final scope = e.scope;
    e.when(
      isTable: (table) {
        _resolve(table, scope);
      },
      isSelect: (select) {},
      isJoin: (join) {},
    );

    visitChildren(e);
  }
}
