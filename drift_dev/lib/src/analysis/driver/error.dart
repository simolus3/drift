import 'package:analyzer/dart/ast/syntactic_entity.dart' as dart;
import 'package:analyzer/dart/element/element.dart' as dart;
import 'package:source_gen/source_gen.dart';
import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart' as sql;

class DriftAnalysisError {
  final SourceSpan? span;
  final String message;

  DriftAnalysisError(this.span, this.message);

  factory DriftAnalysisError.forDartElement(
      dart.Element element, String message) {
    return DriftAnalysisError(
      spanForElement(element),
      message,
    );
  }

  factory DriftAnalysisError.inDartAst(
      dart.Element element, dart.SyntacticEntity entity, String message) {
    final span = spanForElement(element) as FileSpan;

    return DriftAnalysisError(
      span.file.span(entity.offset, entity.end),
      message,
    );
  }

  factory DriftAnalysisError.inDriftFile(
      sql.SyntacticEntity sql, String message) {
    return DriftAnalysisError(sql.span, message);
  }

  factory DriftAnalysisError.fromSqlError(sql.AnalysisError error) {
    var message = error.message ?? '';
    if (error.type == sql.AnalysisErrorType.notSupportedInDesiredVersion) {
      message =
          '$message\nNote: You can change the assumed sqlite version with build '
          'options. See https://drift.simonbinder.eu/options/#assumed-sql-environment for details!';
    }

    return DriftAnalysisError(error.span, message);
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
}
