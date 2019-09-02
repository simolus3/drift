import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

/// Base class for errors that can be presented to an user.
class MoorError {
  final Severity severity;
  final String message;

  MoorError({@required this.severity, this.message});
}

class ErrorInDartCode extends MoorError {
  final Element affectedElement;

  ErrorInDartCode(
      {String message,
      this.affectedElement,
      Severity severity = Severity.warning})
      : super(severity: severity, message: message);
}

class ErrorInMoorFile extends MoorError {
  final FileSpan span;

  ErrorInMoorFile(
      {@required this.span,
      String message,
      Severity severity = Severity.warning})
      : super(message: message, severity: severity);
}

class ErrorSink {
  final List<MoorError> _errors = [];
  UnmodifiableListView<MoorError> get errors => UnmodifiableListView(_errors);

  void report(MoorError error) {
    _errors.add(error);
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
