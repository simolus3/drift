import 'package:analyzer/dart/element/element.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/analyzer/runner/results.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/session.dart';
import 'package:moor_generator/src/backends/backend.dart';
import 'package:sqlparser/sqlparser.dart';

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

  final Set<FoundFile> _analyzedFiles = {};
  final List<FoundFile> _unhandled = [];

  Task(this.session, this.input, this.backend);

  /// Returns an iterable of [FoundFile]s that were analyzed by this task.
  Iterable<FoundFile> get analyzedFiles => _analyzedFiles;

  Future runTask() async {
    // step 1: parse all files included by the input
    _unhandled.clear();
    _unhandled.add(input);
    while (_unhandled.isNotEmpty) {
      final file = _unhandled.removeLast();
      final step = await _parse(file);

      // the step can be null when a file that has already been parsed or even
      // analyzed is encountered (for instance because of an import)
      if (step != null) {
        file.errors.consume(step.errors);
      }

      _analyzedFiles.add(file);
    }

    // step 2: resolve queries in the input.
    // todo we force that moor files are analyzed first because they contain
    // resolved queries which are copied into database accessors. Can we find
    // a way to remove this special-handling?
    final moorFiles = _analyzedFiles.where((f) => f.type == FileType.moor);
    final otherFiles = _analyzedFiles.where((f) => f.type != FileType.moor);

    for (final file in moorFiles.followedBy(otherFiles)) {
      file.errors.clearNonParsingErrors();
      await _analyze(file);
    }

    session.notifyTaskFinished(this);
  }

  Future<Step> _parse(FoundFile file) async {
    if (file.isParsed) {
      // already parsed, nothing to do :)
      return null;
    }

    Step createdStep;
    file.errors.clearAll();
    final resolvedImports = <FoundFile>{};

    switch (file.type) {
      case FileType.moor:
        final content = await backend.readMoor(file.uri);
        final step = createdStep = ParseMoorStep(this, file, content);

        ParsedMoorFile parsed;
        try {
          parsed = await step.parseFile();
        } on Exception catch (e) {
          file.errors.report(MoorError(
            severity: Severity.error,
            message: 'Could not parse file: $e',
          )..wasDuringParsing = true);
          break;
        }
        file.currentResult = parsed;

        parsed.resolvedImports = <ImportStatement, FoundFile>{};
        for (final import in parsed.imports) {
          if (import.importedFile == null) {
            // invalid import statement, this can happen as the user is typing
            continue;
          }

          final found = await _resolveOrReportError(file, import.importedFile,
              (errorMsg) {
            step.reportError(ErrorInMoorFile(
              span: import.importString.span,
              severity: Severity.error,
              message: errorMsg,
            ));
          });

          if (found != null) {
            resolvedImports.add(found);
            parsed.resolvedImports[import] = found;
          }
        }
        break;
      case FileType.dartLibrary:
        LibraryElement library;
        try {
          library = await backend.resolveDart(file.uri);
        } on NotALibraryException catch (_) {
          file.type = FileType.other;
          break;
        }
        final step = createdStep = ParseDartStep(this, file, library);

        final parsed = await step.parse();
        file.currentResult = parsed;

        final daosAndDatabases = parsed.declaredDaos
            .cast<BaseMoorAccessor>()
            .followedBy(parsed.declaredDatabases);

        for (final accessor in daosAndDatabases) {
          final resolvedForAccessor = <FoundFile>[];

          for (final import in accessor.declaredIncludes) {
            final found = await _resolveOrReportError(file, import, (errorMsg) {
              step.reportError(ErrorInDartCode(
                affectedElement: accessor.fromClass,
                severity: Severity.error,
                message: errorMsg,
              ));
            });
            if (found != null) {
              resolvedImports.add(found);
              resolvedForAccessor.add(found);
            }
          }

          accessor.imports = resolvedForAccessor;
        }
        break;
      default:
        // nothing to do here
        break;
    }

    file.state = FileState.parsed;
    session.fileGraph.setImports(file, resolvedImports.toList());
    _notifyFilesNeedWork(resolvedImports);
    return createdStep;
  }

  Future<FoundFile> _resolveOrReportError(
    FoundFile file,
    String import,
    void Function(String) reporter,
  ) async {
    final found = session.resolve(file, import);

    if (found == null) {
      reporter('Invalid import: $import');
    } else if (!await backend.exists(found.uri)) {
      reporter('Imported file does not exist: $import');
    } else {
      return found;
    }

    return null;
  }

  /// Crawls through all (transitive) imports of the provided [roots]. Each
  /// [FoundFile] in the iterable provides queries and tables that are available
  /// to the entity that imports them.
  ///
  /// This is different to [FileGraph.crawl] because imports are not accurate on
  /// Dart files: Two accessors in a single Dart file could reference different
  /// imports, but the [FileGraph] would only know about the union.
  Iterable<FoundFile> crawlImports(Iterable<FoundFile> roots) sync* {
    final found = <FoundFile>{};
    final unhandled = roots.toList();

    while (unhandled.isNotEmpty) {
      final available = unhandled.removeLast();
      found.add(available);
      yield available;

      var importsFromHere = const Iterable<FoundFile>.empty();
      if (available.type == FileType.moor) {
        importsFromHere =
            (available.currentResult as ParsedMoorFile).resolvedImports.values;
      }

      for (final next in importsFromHere) {
        if (!found.contains(next) && !unhandled.contains(next)) {
          unhandled.add(next);
        }
      }
    }
  }

  Future<void> _analyze(FoundFile file) async {
    // skip if already analyzed.
    if (file.state == FileState.analyzed) return;

    Step step;

    switch (file.type) {
      case FileType.dartLibrary:
        step = AnalyzeDartStep(this, file)..analyze();
        break;
      case FileType.moor:
        step = AnalyzeMoorStep(this, file)..analyze();
        break;
      default:
        break;
    }

    file.state = FileState.analyzed;
    if (step != null) {
      file.errors.consume(step.errors);
    }
  }

  void _notifyFilesNeedWork(Iterable<FoundFile> files) {
    for (final file in files) {
      if (!_analyzedFiles.contains(file) && !_unhandled.contains(file)) {
        _unhandled.add(file);
      }
    }
  }

  void printErrors() {
    final foundErrors = _analyzedFiles.expand((file) => file.errors.errors);
    if (foundErrors.isNotEmpty) {
      final log = backend.log;

      log.warning('There were some errors while running moor_generator on '
          '${backend.entrypoint}:');

      for (final error in foundErrors) {
        final printer = error.isError ? log.warning : log.info;
        error.writeDescription(printer);
      }
    }
  }
}
