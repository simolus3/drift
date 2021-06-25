//@dart=2.9
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/backends/plugin/plugin.dart';

const _genericError = 'moor.errorGeneric';

/// Sends information about errors, lints and warnings encountered in a `.moor`
/// file to the analyzer.
class ErrorService {
  final MoorPlugin plugin;

  ErrorService(this.plugin);

  void handleResult(FoundFile analyzedFile) {
    final errors = <AnalysisError>[];
    final path = analyzedFile.uri.path;

    if (analyzedFile.isParsed) {
      for (final error in analyzedFile.errors.errors) {
        // this is a parsing error, high severity
        final severity = error.isError
            ? AnalysisErrorSeverity.ERROR
            : AnalysisErrorSeverity.WARNING;

        final type = error.wasDuringParsing
            ? AnalysisErrorType.SYNTACTIC_ERROR
            : AnalysisErrorType.COMPILE_TIME_ERROR;

        final location = _findLocationForError(error, path);

        errors.add(AnalysisError(
            severity, type, location, error.message, _genericError));
      }
    }

    final params = AnalysisErrorsParams(path, errors);
    plugin.channel.sendNotification(params.toNotification());
  }

  Location _findLocationForError(MoorError error, String path) {
    if (error is ErrorInMoorFile) {
      final span = error.span;
      final start = span.start;
      final end = span.end;
      return Location(path, start.offset, span.length, start.line + 1,
          start.column + 1, end.line + 1, end.column + 1);
    }

    return Location(path, 0, 0, 0, 0, 0, 0);
  }
}
