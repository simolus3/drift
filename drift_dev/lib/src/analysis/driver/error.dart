import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart' as sql;

class DriftAnalysisError {
  final SourceSpan? span;
  final String message;

  DriftAnalysisError(this.span, this.message);

  factory DriftAnalysisError.inDriftFile(
      sql.SyntacticEntity sql, String message) {
    return DriftAnalysisError(sql.span, message);
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
