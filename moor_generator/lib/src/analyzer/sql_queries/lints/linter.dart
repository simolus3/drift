import 'package:sqlparser/sqlparser.dart';

import '../query_handler.dart';

/// Provides additional hints that aren't implemented in the sqlparser because
/// they're specific to moor.
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
  void visitResultColumn(ResultColumn e) {
    super.visitResultColumn(e);

    if (e is ExpressionResultColumn) {
      // The generated code will be invalid if knowing the expression is needed
      // to know the column name (e.g. it's a Dart template without an AS), or
      // if the type is unknown.
      final expression = e.expression;
      final resolveResult = linter.handler.context.typeOf(expression);

      if (resolveResult.type == null) {
        linter.lints.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: 'Expression has an unknown type, the generated code can be'
              ' inaccurate.',
          relevantNode: expression,
        ));
      }

      final dependsOnPlaceholder = e.as == null &&
          expression.allDescendants.whereType<DartPlaceholder>().isNotEmpty;
      if (dependsOnPlaceholder) {
        linter.lints.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: 'The name of this column depends on a Dart template, which '
              'breaks generated code. Try adding an `AS` alias to fix this.',
          relevantNode: e,
        ));
      }
    }
  }

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
        final msg = notPresent.map((c) => c.name.name).join(', ');

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
