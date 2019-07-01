part of 'analysis.dart';

class AnalysisError {
  final AstNode relevantNode;
  final String message;
  final AnalysisErrorType type;

  AnalysisError({@required this.type, this.message, this.relevantNode});

  @override
  String toString() {
    final first = relevantNode?.first?.span;
    final last = relevantNode?.last?.span;

    if (first != null && last != null) {
      final span = first.expand(last);
      return span.message(message ?? type.toString(), color: true);
    } else {
      return 'Error: $type: $message at $relevantNode';
    }
  }
}

enum AnalysisErrorType {
  referencedUnknownTable,
  referencedUnknownColumn,
  ambiguousReference,

  unknownFunction,
}
