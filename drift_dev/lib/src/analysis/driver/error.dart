import 'package:analyzer/dart/ast/syntactic_entity.dart' as dart;
import 'package:analyzer/dart/element/element.dart' as dart;
import 'package:source_gen/source_gen.dart';
import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart' as sql;

enum DriftAnalysisErrorLevel { warning, error }

class DriftAnalysisError {
  final SourceSpan? span;
  final String message;
  final DriftAnalysisErrorLevel level;

  DriftAnalysisError(this.span, this.message,
      {this.level = DriftAnalysisErrorLevel.error});

  factory DriftAnalysisError.forDartElement(
      dart.Element element, String message,
      {DriftAnalysisErrorLevel level = DriftAnalysisErrorLevel.error}) {
    return DriftAnalysisError(spanForElement(element), message, level: level);
  }

  factory DriftAnalysisError.inDartAst(
      dart.Element element, dart.SyntacticEntity entity, String message,
      {DriftAnalysisErrorLevel level = DriftAnalysisErrorLevel.error}) {
    return DriftAnalysisError(dartAstSpan(element, entity), message,
        level: level);
  }

  factory DriftAnalysisError.inDriftFile(
      sql.SyntacticEntity sql, String message,
      {DriftAnalysisErrorLevel level = DriftAnalysisErrorLevel.error}) {
    return DriftAnalysisError(sql.span, message, level: level);
  }

  factory DriftAnalysisError.fromSqlError(sql.AnalysisError error,
      {DriftAnalysisErrorLevel level = DriftAnalysisErrorLevel.error}) {
    var message = error.message ?? '';
    if (error.type == sql.AnalysisErrorType.notSupportedInDesiredVersion) {
      message =
          '$message\nNote: You can change the assumed sqlite version with build '
          'options. See https://drift.simonbinder.eu/options/#assumed-sql-environment for details!';
    }

    return DriftAnalysisError(error.span, message, level: level);
  }

  @override
  String toString() {
    final span = this.span;

    if (span != null) {
      return span.message(message);
    } else {
      return message;
    }
  }

  static FileSpan dartAstSpan(
      dart.Element element, dart.SyntacticEntity entity) {
    final span = spanForElement(element) as FileSpan;
    return span.file.span(entity.offset, entity.end);
  }
}
