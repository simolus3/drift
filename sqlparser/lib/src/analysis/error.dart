part of 'analysis.dart';

class AnalysisError {
  final AstNode relevantNode;
  final String message;
  final AnalysisErrorType type;

  AnalysisError({@required this.type, this.message, this.relevantNode});
}

enum AnalysisErrorType {
  referencedUnknownTable,
  referencedUnknownColumn,
  ambiguousReference,
}
