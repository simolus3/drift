import 'package:sqlparser/sqlparser.dart';

import '../../resolver.dart';

/// Implements (mostly drift-specific) lints for SQL statements that aren't
/// implementeed in `sqlparser`.
class DriftSqlLinter {
  final AnalysisContext _context;
  final LocalElementResolver _resolver;

  final List<AnalysisError> sqlParserErrors = [];

  DriftSqlLinter(this._context, this._resolver);

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
}
