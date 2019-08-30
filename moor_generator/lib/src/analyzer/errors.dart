import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';

/// Base class for errors that can be presented to an user.
class MoorError {
  final Severity severity;

  MoorError(this.severity);
}

class ErrorInDartCode extends MoorError {
  final String message;
  final Element affectedElement;

  ErrorInDartCode(
      {this.message,
      this.affectedElement,
      Severity severity = Severity.warning})
      : super(severity);
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

  warning,
  info,
  hint
}
