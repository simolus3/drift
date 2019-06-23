part of '../analysis.dart';

class ReferenceResolver extends NoopVisitor<void> {
  final ReferenceScope scope;
  final AnalysisContext context;

  ReferenceResolver(this.scope, this.context);

  @override
  void visitFunction(FunctionExpression e) {
    e.resolved = scope.resolve<SqlFunction>(e.name);
    visitChildren(e);
  }

  @override
  void visitReference(Reference e) {
    if (e.tableName != null) {
      // first find the referenced table, then use the column on that table.
      final tbl = scope.resolve<ResolvesToResultSet>(e.tableName)?.resultSet;
      if (tbl == null) {
        context.reportError(AnalysisError(
          type: AnalysisErrorType.referencedUnknownTable,
          relevantNode: e,
        ));
      } else {
        final column = tbl.findColumn(e.columnName);
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
      final tables = scope.allOf<ResolvesToResultSet>();
      final columns = tables
          .map((t) => t.resultSet.findColumn(e.columnName))
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

  @override
  void visitQueryable(Queryable e) {
    e.when(
      isTable: (table) {
        final resolvedTable = scope.resolve<Table>(table.tableName);
        table.resolved = resolvedTable;

        if (table.as != null) {
          scope.register(table.as, table);
        }
      },
      isSelect: (select) {
        if (select.as != null) {
          scope.register(select.as, select.statement);
        }
      },
      isJoin: (join) {},
    );
  }

  @override
  void visitJoin(Join e) {}

  @override
  void visitSelectStatement(SelectStatement e) {
    // nested statement! create a new scope
    final childResolver = _fork();

    // first visit the FROM clause so we have the references available from
    // the start.
    for (var source in e.from) {
      source.accept(childResolver);
    }

    // now, visit everything else
    for (var child in e.childNodes) {
      if (child is! Queryable) {
        child.accept(childResolver);
      }
    }
  }

  ReferenceResolver _fork() {
    return ReferenceResolver(scope.createChild(), context);
  }
}
