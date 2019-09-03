import 'package:sqlparser/sqlparser.dart';

import '../query_handler.dart';

class Linter {
  final QueryHandler handler;
  final List<AnalysisError> lints = [];

  Linter(this.handler);

  void reportLints() {
    handler.context.root.accept(_LintingVisitor(this));
  }
}

class _LintingVisitor extends RecursiveVisitor<void> {
  final Linter linter;

  _LintingVisitor(this.linter);

  @override
  void visitInsertStatement(InsertStatement e) {
    final targeted = e.resolvedTargetColumns;
    if (targeted == null) return;

    // First, check that the amount of values matches the declaration.
    e.source.when(
      isValues: (values) {
        for (var tuple in values.values) {
          if (tuple.expressions.length != targeted.length) {
            linter.lints.add(AnalysisError(
              type: AnalysisErrorType.other,
              message: 'Expected tuple to have ${targeted.length} values',
              relevantNode: tuple,
            ));
          }
        }
      },
      isSelect: (select) {
        final columns = select.stmt.resolvedColumns;

        if (columns.length != targeted.length) {
          linter.lints.add(AnalysisError(
            type: AnalysisErrorType.other,
            message: 'This select statement should return ${targeted.length} '
                'columns, but actually returns ${columns.length}',
            relevantNode: select.stmt,
          ));
        }
      },
    );

    // second, check that no required columns are left out
    final specifiedTable =
        linter.handler.mapper.tableToMoor(e.table.resolved as Table);
    final required =
        specifiedTable.columns.where((c) => c.requiredDuringInsert).toList();

    if (required.isNotEmpty && e.source is DefaultValues) {
      linter.lints.add(AnalysisError(
        type: AnalysisErrorType.other,
        message: 'This table has columns without default values, so defaults '
            'can\'t be used for insert.',
        relevantNode: e.table,
      ));
    } else {
      final notPresent = required.where((c) => !targeted
          .any((t) => t.name.toUpperCase() == c.name.name.toUpperCase()));

      if (notPresent.isNotEmpty) {
        final msg = notPresent.join(', ');

        linter.lints.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: 'Some columns are required but not present here. Expected '
              'values for $msg.',
          relevantNode: e.source.childNodes.first,
        ));
      }
    }
  }
}
