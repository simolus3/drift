import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_span/source_span.dart';
import 'package:sqlparser/sqlparser.dart';

typedef LogFunction = void Function(dynamic message,
    [Object error, StackTrace stackTrace]);

/// Base class for errors that can be presented to a user.
class MoorError {
  final Severity severity;
  final String message;

  bool wasDuringParsing = true;

  MoorError({@required this.severity, this.message});

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

class ErrorInDartCode extends MoorError {
  final Element affectedElement;

  ErrorInDartCode(
      {String message,
      this.affectedElement,
      Severity severity = Severity.warning})
      : super(severity: severity, message: message);

  @override
  void writeDescription(LogFunction log) {
    if (affectedElement != null) {
      final span = spanForElement(affectedElement);
      log(span.message(message));
    } else {
      log(message);
    }
  }
}

class ErrorInMoorFile extends MoorError {
  final FileSpan span;

  ErrorInMoorFile(
      {@required this.span,
      String message,
      Severity severity = Severity.warning})
      : super(message: message, severity: severity);

  factory ErrorInMoorFile.fromSqlParser(AnalysisError error,
      {Severity overrideSeverity}) {
    return ErrorInMoorFile(
      span: error.span,
      message: error.message ?? error.type.toString(),
      severity: overrideSeverity ?? Severity.error,
    );
  }

  @override
  void writeDescription(LogFunction log) {
    log(span.message(message, color: isError));
  }
}

class ErrorSink {
  final List<MoorError> _errors = [];
  UnmodifiableListView<MoorError> get errors => UnmodifiableListView(_errors);

  void report(MoorError error) {
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
