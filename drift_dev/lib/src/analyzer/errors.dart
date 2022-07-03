import 'package:analyzer/dart/ast/ast.dart' as dart;
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart';

typedef LogFunction = void Function(dynamic message,
    [Object? error, StackTrace? stackTrace]);

/// Base class for errors that can be presented to a user.
class DriftError {
  final Severity severity;
  final String message;

  bool wasDuringParsing = true;

  DriftError({required this.severity, required this.message});

  bool get isError =>
      severity == Severity.criticalError || severity == Severity.error;

  @override
  String toString() {
    final builder = StringBuffer();
    writeDescription((msg, [_, __]) => builder.writeln(msg));
    return 'Error: $builder';
  }

  void writeDescription(LogFunction log) {
    log(message);
  }
}

class ErrorInDartCode extends DriftError {
  final Element? affectedElement;
  final dart.AstNode? affectedNode;

  ErrorInDartCode({
    required String message,
    this.affectedElement,
    this.affectedNode,
    Severity severity = Severity.warning,
  }) : super(severity: severity, message: message);

  SourceSpan? get span {
    if (affectedElement != null) {
      final span = spanForElement(affectedElement!);

      final node = affectedNode;
      if (node != null) {
        if (span is FileSpan) {
          return span.file.span(node.offset, node.offset + node.length);
        } else {
          final start = SourceLocation(node.offset, sourceUrl: span.sourceUrl);
          final end = SourceLocation(node.offset + node.length,
              sourceUrl: span.sourceUrl);
          return SourceSpan(start, end, node.toSource());
        }
      }

      return span;
    }

    return null;
  }

  @override
  void writeDescription(LogFunction log) {
    final span = this.span;

    if (span != null) {
      log(span.message(message));
    } else {
      log(message);
    }
  }
}

class ErrorInDriftFile extends DriftError {
  final FileSpan span;

  ErrorInDriftFile(
      {required this.span,
      required String message,
      Severity severity = Severity.warning})
      : super(message: message, severity: severity);

  factory ErrorInDriftFile.fromSqlParser(AnalysisError error,
      {Severity? overrideSeverity}) {
    // Describe how to change the sqlite version for errors caused by a wrong
    // version
    var msg = error.message ?? error.type.toString();
    if (error.type == AnalysisErrorType.notSupportedInDesiredVersion) {
      msg = '$msg\nNote: You can change the assumed sqlite version with build '
          'options. See https://drift.simonbinder.eu/options/#assumed-sql-environment for details!';
    }

    final defaultSeverity =
        error.type == AnalysisErrorType.hint ? Severity.hint : Severity.error;

    return ErrorInDriftFile(
      span: error.span!,
      message: msg,
      severity: overrideSeverity ?? defaultSeverity,
    );
  }

  @override
  void writeDescription(LogFunction log) {
    log(span.message(message, color: isError));
  }
}

class ErrorSink {
  final List<DriftError> _errors = [];
  UnmodifiableListView<DriftError> get errors => UnmodifiableListView(_errors);

  void report(DriftError error) {
    _errors.add(error);
  }

  void clearAll() {
    _errors.clear();
  }

  void clearNonParsingErrors() {
    _errors.removeWhere((e) => !e.wasDuringParsing);
  }

  void consume(ErrorSink other) {
    _errors.addAll(other._errors);
  }
}

enum Severity {
  /// A severe error. We might not be able to generate correct or consistent
  /// code when errors with these severity are present.
  criticalError,

  /// An error. The generated code won't have major problems, but might cause
  /// runtime errors. For instance, this is used when we get sql that has
  /// semantic errors.
  error,

  /// A warning is used when the code affected is technically valid, but
  /// unlikely to do what the user expects.
  warning,
  info,
  hint
}
