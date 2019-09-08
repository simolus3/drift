import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:moor_generator/src/backends/plugin/plugin.dart';

const _parsingErrorCode = 'moor.parsingError';

/// Sends information about errors, lints and warnings encountered in a `.moor`
/// file to the analyzer.
class ErrorService {
  final MoorPlugin plugin;

  ErrorService(this.plugin);

  void handleMoorResult(MoorTask completedTask) {
    final result = completedTask.lastResult.parseResult;
    final path = completedTask.backendTask.entrypoint.path;

    final errors = <AnalysisError>[];

    for (var error in result.errors) {
      // this is a parsing error, high severity
      final severity = AnalysisErrorSeverity.ERROR;
      final type = AnalysisErrorType.SYNTACTIC_ERROR;

      final sourceSpan = error.token.span;
      final start = sourceSpan.start;
      final location = Location(
          path, start.offset, sourceSpan.length, start.line, start.column);

      errors.add(AnalysisError(
          severity, type, location, error.message, _parsingErrorCode));
    }

    final params = AnalysisErrorsParams(path, errors);
    plugin.channel.sendNotification(params.toNotification());
  }
}
