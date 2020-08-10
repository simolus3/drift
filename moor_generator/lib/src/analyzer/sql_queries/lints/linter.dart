import 'package:moor_generator/moor_generator.dart' show MoorColumn;
import 'package:sqlparser/sqlparser.dart';

import '../query_handler.dart';
import '../type_mapping.dart';

/// Provides additional hints that aren't implemented in the sqlparser because
/// they're specific to moor.
class Linter {
  final AnalysisContext context;
  final TypeMapper mapper;
  final List<AnalysisError> lints = [];
  final bool contextRootIsQuery;

  Linter(this.context, this.mapper, {this.contextRootIsQuery = false});

  Linter.forHandler(QueryHandler handler)
      : context = handler.context,
        mapper = handler.mapper,
        contextRootIsQuery = true;

  void reportLints() {
    context.root.acceptWithoutArg(_LintingVisitor(this));
  }
}

class _LintingVisitor extends RecursiveVisitor<void, void> {
  final Linter linter;

  _LintingVisitor(this.linter);

  @override
  void visitBinaryExpression(BinaryExpression e, void arg) {
    const numericOps = {
      TokenType.plus,
      TokenType.minus,
      TokenType.star,
      TokenType.slash,
    };
    const binaryOps = {
      TokenType.shiftLeft,
      TokenType.shiftRight,
      TokenType.pipe,
      TokenType.ampersand,
      TokenType.percent,
    };

    final operator = e.operator.type;

    void checkTypesFor(List<BasicType> allowed, String message) {
      for (final child in e.childNodes) {
        final type = linter.context.typeOf(child as Expression);
        if (type.unknown) continue;

        if (!allowed.contains(type.type.type)) {
          linter.lints.add(AnalysisError(
            type: AnalysisErrorType.other,
            message: message,
            relevantNode: child,
          ));
        }
      }
    }

    if (numericOps.contains(operator)) {
      checkTypesFor(
        [BasicType.int, BasicType.real],
        'Expression should be numeric, the resulting value might be unexpected',
      );
    }
    if (binaryOps.contains(operator)) {
      checkTypesFor(
        [BasicType.int],
        'Expression should be an int, the resulting value might be unexpected',
      );
    }
  }

  @override
  void visitResultColumn(ResultColumn e, void arg) {
    super.visitResultColumn(e, arg);

    if (e is ExpressionResultColumn) {
      // The generated code will be invalid if knowing the expression is needed
      // to know the column name (e.g. it's a Dart template without an AS), or
      // if the type is unknown.
      final expression = e.expression;
      final resolveResult = linter.context.typeOf(expression);

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

    if (e is NestedStarResultColumn) {
      // check that a table.** column only appears in a top-level select
      // statement
      if (!linter.contextRootIsQuery || e.parent != linter.context.root) {
        linter.lints.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: 'Nested star columns may only appear in a top-level select '
              "query. They're not supported in compound selects or select "
              'expressions',
          relevantNode: e,
        ));
      }

      // check that it actually refers to a table
      if (e.resultSet is! Table) {
        linter.lints.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: 'Nested star columns must refer to a table directly. They '
              "can't refer to a table-valued function or another select "
              'statement.',
          relevantNode: e,
        ));
      }
    }
  }

  @override
  void visitInsertStatement(InsertStatement e, void arg) {
    final targeted = e.resolvedTargetColumns;
    if (targeted == null) return;

    // First, check that the amount of values matches the declaration.
    e.source.when(
      isValues: (values) {
        for (final tuple in values.values) {
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
    final resolved = e.table.resolved;
    List<MoorColumn> required;
    if (resolved is Table) {
      final specifiedTable =
          linter.mapper.tableToMoor(e.table.resolved as Table);
      required = specifiedTable.columns
          .where(specifiedTable.isColumnRequiredForInsert)
          .toList();
    } else {
      required = const [];
    }

    if (required.isNotEmpty && e.source is DefaultValues) {
      linter.lints.add(AnalysisError(
        type: AnalysisErrorType.other,
        message: 'This table has columns without default values, so defaults '
            'can\'t be used for insert.',
        relevantNode: e.table,
      ));
    } else {
      final notPresent = required.where((c) {
        return !targeted
            .any((t) => t?.name?.toUpperCase() == c.name.name.toUpperCase());
      });

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
