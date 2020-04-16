part of 'analysis.dart';

class AnalysisError {
  final AstNode relevantNode;
  final String message;
  final AnalysisErrorType type;

  AnalysisError({@required this.type, this.message, this.relevantNode});

  /// The relevant portion of the source code that caused this error. Some AST
  /// nodes don't have a span, in that case this error is going to be null.
  FileSpan get span {
    final first = relevantNode?.first?.span;
    final last = relevantNode?.last?.span;

    if (first != null && last != null) {
      return first.expand(last);
    }
    return null;
  }

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
      {@required AnalysisErrorType type,
      this.reference,
      this.available,
      AstNode relevantNode})
      : super(type: type, relevantNode: relevantNode);

  @override
  String get message {
    return 'Could not find $reference. Available are: ${available.join(', ')}';
  }
}

enum AnalysisErrorType {
  referencedUnknownTable,
  referencedUnknownColumn,
  ambiguousReference,

  /// Note that most syntax errors are reported as [ParsingError]
  synctactic,

  unknownFunction,
  compoundColumnCountMismatch,
  cteColumnCountMismatch,
  valuesSelectCountMismatch,
  other,
}
