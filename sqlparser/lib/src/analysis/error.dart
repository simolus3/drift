part of 'analysis.dart';

class AnalysisError {
  final SyntacticEntity? source;

  final String? message;
  final AnalysisErrorType type;

  AnalysisError._internal(this.type, this.message, this.source);

  AnalysisError(
      {required this.type, this.message, SyntacticEntity? relevantNode})
      : source = relevantNode;

  @Deprecated('Use source instead')
  AstNode? get relevantNode => source as AstNode?;

  factory AnalysisError.fromParser(ParsingError error) {
    return AnalysisError._internal(
      AnalysisErrorType.synctactic,
      error.message,
      error.token,
    );
  }

  /// The relevant portion of the source code that caused this error. Some AST
  /// nodes don't have a span, in that case this error is going to have a null
  /// span as well.
  FileSpan? get span => source!.span;

  @override
  String toString() {
    final msgSpan = span;
    if (msgSpan != null) {
      return msgSpan.message(message ?? type.toString(), color: true);
    } else {
      return 'Error: $type: $message at $relevantNode';
    }
  }
}

class UnresolvedReferenceError extends AnalysisError {
  /// The attempted reference that couldn't be resolved
  final String reference;

  /// A list of alternative references that would be available for [reference].
  final Iterable<String> available;

  UnresolvedReferenceError(
      {required AnalysisErrorType type,
      required this.reference,
      required this.available,
      AstNode? relevantNode})
      : super(type: type, relevantNode: relevantNode);

  @override
  String get message {
    return 'Could not find $reference. Available are: ${available.join(', ')}';
  }
}

enum AnalysisErrorType {
  duplicatePrimaryKeyDeclaration,
  referencedUnknownTable,
  referencedUnknownColumn,
  ambiguousReference,
  synctactic,
  unknownFunction,
  compoundColumnCountMismatch,
  cteColumnCountMismatch,
  valuesSelectCountMismatch,
  viewColumnNamesMismatch,
  rowValueMisuse,
  notSupportedInDesiredVersion,
  illegalUseOfReturning,
  other,
}
