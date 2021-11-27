import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/runner/steps.dart';

Exception analysisError(Step step, Element element, String message) {
  final error = ErrorInDartCode(
    message: message,
    severity: Severity.criticalError,
    affectedElement: element,
  );
  step.reportError(error);
  return AnalysisException(error.toString());
}
