import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:moor_generator/src/backends/backend.dart';
import 'package:moor_generator/src/model/specified_db_classes.dart';

/// A task is used to fully parse and analyze files based on an input file. To
/// analyze that file, all transitive imports will have to be analyzed as well.
///
/// Analyzing works in two steps:
///  1. parsing and reading the structure: For each Dart file we encounter, we
///     read all `UseMoor` and `UseDao` structures. We also read all `Table`
///     classes defined in that file.
///  2. analyzing: Now that we have the table and database structure available,
///     can use that to analyze sql queries for semantic errors.
///
/// The results of parsing a set of files is stored in a [MoorSession].
class Task {
  final FoundFile input;
  final MoorSession session;
  final BackendTask backend;

  final Map<FoundFile, Step> _performedSteps = {};
  final List<FoundFile> _unhandled = [];

  Task(this.session, this.input, this.backend);

  Future runTask() async {
    // step 1: parse all files included by the input
    _unhandled.clear();
    _unhandled.add(input);
    while (_unhandled.isNotEmpty) {
      await _parse(_unhandled.removeLast());
    }

    // step 2: resolve queries in the input
    for (var file in _performedSteps.keys) {
      await _analyze(file);
    }
  }

  Future<void> _parse(FoundFile file) async {
    final resolvedImports = <FoundFile>{};
    if (file.state != FileState.dirty) {
      // already parsed, nothing to do :)
      return;
    }

    switch (file.type) {
      case FileType.moor:
        final content = await backend.readMoor(file.uri);
        final step = ParseMoorFile(this, file, content);
        _performedSteps[file] = step;

        final parsed = await step.parseFile();
        file.currentResult = parsed;

        for (var import in parsed.parsedFile.imports) {
          final found = session.resolve(file, import.importedFile);
          if (!await backend.exists(found.uri)) {
            step.reportError(ErrorInMoorFile(
              span: import.importString.span,
              severity: Severity.error,
              message: 'File does not exist: ${import.importedFile}',
            ));
          } else {
            resolvedImports.add(found);
          }
        }
        break;
      case FileType.dart:
        final library = await backend.resolveDart(file.uri);
        final step = ParseDartStep(this, file, library);
        _performedSteps[file] = step;

        final parsed = await step.parse();
        file.currentResult = parsed;

        final daosAndDatabases = parsed.declaredDaos
            .cast<SpecifiedDbAccessor>()
            .followedBy(parsed.declaredDatabases);

        for (var accessor in daosAndDatabases) {
          final resolvedForAccessor = <FoundFile>[];

          for (var import in accessor.includes) {
            final found = session.resolve(file, import);
            if (!await backend.exists(found.uri)) {
              step.reportError(ErrorInDartCode(
                affectedElement: accessor.fromClass,
                severity: Severity.error,
                message: 'Include could not be resolved: $import',
              ));
            } else {
              resolvedImports.add(found);
              resolvedForAccessor.add(found);
            }
          }

          accessor.resolvedImports = resolvedForAccessor;
        }
        break;
      default:
        break;
    }

    file.state = FileState.parsed;
    session.fileGraph.setImports(file, resolvedImports.toList());
    _notifyFilesNeedWork(resolvedImports);
  }

  Future<void> _analyze(FoundFile file) async {
    // skip if already analyzed.
    if (file.state == FileState.analyzed) return;

    switch (file.type) {
      case FileType.dart:
        AnalyzeDartStep(this, file).analyze();
        break;
      default:
        break;
    }

    file.state = FileState.analyzed;
  }

  void _notifyFilesNeedWork(Iterable<FoundFile> files) {
    for (var file in files) {
      if (!_performedSteps.containsKey(file) && !_unhandled.contains(file)) {
        _unhandled.add(file);
      }
    }
  }

  void printErrors() {
    final foundErrors =
        _performedSteps.values.expand((step) => step.errors.errors);
    if (foundErrors.isNotEmpty) {
      final log = backend.log;

      log.warning('There were some errors while running moor_generator on '
          '${backend.entrypoint}:');

      for (var error in foundErrors) {
        final printer = error.isError ? log.warning : log.info;
        error.writeDescription(printer);
      }
    }
  }
}
