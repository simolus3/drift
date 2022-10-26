import 'package:collection/collection.dart';
import 'package:sqlparser/sqlparser.dart';

import '../../../results/results.dart' hide ResultColumn;

/// Implements (mostly drift-specific) lints for SQL statements that aren't
/// implementeed in `sqlparser`.
class DriftSqlLinter {
  final AnalysisContext _context;
  final bool _contextRootIsQuery;
  final Iterable<DriftElement> references;

  final List<AnalysisError> sqlParserErrors = [];

  DriftSqlLinter(
    this._context, {
    bool contextRootIsQuery = false,
    required this.references,
  }) : _contextRootIsQuery = contextRootIsQuery;

  void collectLints() {
    _context.root.acceptWithoutArg(_LintingVisitor(this));
  }
}

class _LintingVisitor extends RecursiveVisitor<void, void> {
  final DriftSqlLinter linter;

  _LintingVisitor(this.linter);

  bool _isTextDateTime(ResolveResult result) {
    final type = result.type;
    return type != null &&
        type.type == BasicType.text &&
        type.hint is IsDateTime;
  }

  @override
  void visitBetweenExpression(BetweenExpression e, void arg) {
    if (_isTextDateTime(linter._context.typeOf(e.check))) {
      linter.sqlParserErrors.add(AnalysisError(
        type: AnalysisErrorType.hint,
        message: 'This compares two date time values lexicographically. '
            'To compare date time values, compare their `unixepoch()` '
            'value instead.',
        relevantNode: e,
      ));
    }

    super.visitBetweenExpression(e, arg);
  }

  @override
  void visitBinaryExpression(BinaryExpression e, void arg) {
    final isForDateTimes = _isTextDateTime(linter._context.typeOf(e.left)) &&
        _isTextDateTime(linter._context.typeOf(e.right));

    if (isForDateTimes) {
      switch (e.operator.type) {
        case TokenType.equal:
        case TokenType.doubleEqual:
        case TokenType.exclamationEqual:
        case TokenType.lessMore:
          linter.sqlParserErrors.add(AnalysisError(
            type: AnalysisErrorType.hint,
            message:
                'Semantically equivalent date time values may be formatted '
                "differently and can't be compared directly. Consider "
                'comparing the `unixepoch()` values of the time value instead.',
            relevantNode: e.operator,
          ));
          break;
        case TokenType.less:
        case TokenType.lessEqual:
        case TokenType.more:
        case TokenType.moreEqual:
          linter.sqlParserErrors.add(AnalysisError(
            type: AnalysisErrorType.hint,
            message: 'This compares two date time values lexicographically. '
                'To compare date time values, compare their `unixepoch()` '
                'value instead.',
            relevantNode: e.operator,
          ));
          break;
        default:
          break;
      }
    }

    super.visitBinaryExpression(e, arg);
  }

  @override
  void visitDriftSpecificNode(DriftSpecificNode e, void arg) {
    if (e is DartPlaceholder) {
      return visitDartPlaceholder(e, arg);
    } else if (e is NestedStarResultColumn) {
      return visitResultColumn(e, arg);
    } else if (e is NestedQueryColumn) {
      return visitResultColumn(e, arg);
    }

    visitChildren(e, arg);
  }

  void visitDartPlaceholder(DartPlaceholder e, void arg) {
    if (e is! DartExpressionPlaceholder) {
      // Default values are supported for expressions only
      if (linter._context.stmtOptions.defaultValuesForPlaceholder
          .containsKey(e.name)) {
        linter.sqlParserErrors.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: 'This placeholder has a default value, which is only '
              'supported for expressions.',
          relevantNode: e,
        ));
      }
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
      final resolveResult = linter._context.typeOf(expression);

      if (resolveResult.type == null) {
        linter.sqlParserErrors.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: 'Expression has an unknown type, the generated code can be'
              ' inaccurate.',
          relevantNode: expression,
        ));
      }

      final dependsOnPlaceholder = e.as == null &&
          expression.allDescendants.whereType<DartPlaceholder>().isNotEmpty;
      if (dependsOnPlaceholder) {
        linter.sqlParserErrors.add(AnalysisError(
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
      if (!linter._contextRootIsQuery || e.parent != linter._context.root) {
        linter.sqlParserErrors.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: 'Nested star columns may only appear in a top-level select '
              "query. They're not supported in compound selects or select "
              'expressions',
          relevantNode: e,
        ));
      }

      // check that it actually refers to a table
      final result = e.resultSet?.unalias();
      if (result is! Table && result is! View) {
        linter.sqlParserErrors.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: 'Nested star columns must refer to a table directly. They '
              "can't refer to a table-valued function or another select "
              'statement.',
          relevantNode: e,
        ));
      }
    }

    if (e is NestedQueryColumn) {
      // check that a LIST(...) column only appears in a top-level select
      // statement
      if (!linter._contextRootIsQuery || e.parent != linter._context.root) {
        linter.sqlParserErrors.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: 'Nested query may only appear in a top-level select '
              "query. They're not supported in compound selects or select "
              'expressions',
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
    final source = e.source;
    if (source is ValuesSource) {
      for (final tuple in source.values) {
        if (tuple.expressions.length != targeted.length) {
          linter.sqlParserErrors.add(AnalysisError(
            type: AnalysisErrorType.other,
            message: 'Expected tuple to have ${targeted.length} values',
            relevantNode: tuple,
          ));
        }
      }
    } else if (source is SelectInsertSource) {
      final columns = source.stmt.resolvedColumns;

      if (columns != null && columns.length != targeted.length) {
        linter.sqlParserErrors.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: 'This select statement should return ${targeted.length} '
              'columns, but actually returns ${columns.length}',
          relevantNode: source.stmt,
        ));
      }
    } else if (source is DartInsertablePlaceholder) {
      // Insertables always cover a full table, so we can't have target columns
      if (e.targetColumns.isNotEmpty) {
        linter.sqlParserErrors.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: "Dart placeholders can't be used here, because this insert "
              'statement explicitly defines the columns to set. Try removing '
              'the columns on the left.',
          relevantNode: source,
        ));
      }
    }

    // second, check that no required columns are left out
    final resolved = e.table.resolved;
    List<DriftColumn> required = const [];
    if (resolved is Table) {
      final driftTable =
          linter.references.firstWhereOrNull((e) => e.id.name == resolved.name);

      if (driftTable is DriftTable) {
        required = driftTable.columns
            .where(driftTable.isColumnRequiredForInsert)
            .toList();
      }
    } else {
      required = const [];
    }

    if (required.isNotEmpty && e.source is DefaultValues) {
      linter.sqlParserErrors.add(AnalysisError(
        type: AnalysisErrorType.other,
        message: 'This table has columns without default values, so defaults '
            'can\'t be used for insert.',
        relevantNode: e.table,
      ));
    } else {
      final notPresent = required.where((c) {
        return !targeted
            .any((t) => t?.name.toUpperCase() == c.nameInSql.toUpperCase());
      });

      if (notPresent.isNotEmpty) {
        final msg = notPresent.map((c) => c.nameInSql).join(', ');

        linter.sqlParserErrors.add(AnalysisError(
          type: AnalysisErrorType.other,
          message: 'Some columns are required but not present here. Expected '
              'values for $msg.',
          relevantNode: e.source.childNodes.first,
        ));
      }
    }
  }
}
